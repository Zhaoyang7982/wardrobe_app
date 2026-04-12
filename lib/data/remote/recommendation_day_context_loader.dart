import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../domain/models/recommendation_day_context.dart';

/// 并行拉取节假日（timor.tech）与天气（Open-Meteo + 可选定位），失败时降级为 [RecommendationDayContext.localFallback] 的扩展信息。
class RecommendationDayContextLoader {
  RecommendationDayContextLoader._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Future<RecommendationDayContext> load({DateTime? now}) async {
    final local = (now ?? DateTime.now()).toLocal();
    final dateStr =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

    final holidayFuture = _loadHoliday(local, dateStr);
    final weatherFuture = _loadWeather();

    final holiday = await holidayFuture;
    final weather = await weatherFuture;

    final weekend =
        local.weekday == DateTime.saturday || local.weekday == DateTime.sunday;

    return RecommendationDayContext(
      localDate: local,
      longDateLabel: DateFormat('y年M月d日', 'zh_CN').format(local),
      weekdayLabel: DateFormat('EEEE', 'zh_CN').format(local),
      isWeekend: weekend,
      isWorkdayFromApi: holiday.isWorkday,
      holidayName: holiday.name,
      temperatureC: weather?.ok == true ? weather!.tempC : null,
      weatherDescription: weather?.ok == true ? weather!.description : null,
      locationHint: weather?.ok == true ? weather!.locationHint : null,
      locationFromLastKnown: weather?.ok == true ? weather!.fromLastKnown : false,
      locationFixTime: weather?.ok == true ? weather!.fixTime : null,
      holidayApiFailed: holiday.apiFailed,
      weatherApiFailed: weather == null || weather.ok != true,
    );
  }

  static Future<({bool isWorkday, String? name, bool apiFailed})> _loadHoliday(
    DateTime local,
    String dateStr,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://timor.tech/api/holiday/info/$dateStr',
      );
      final data = res.data;
      if (data == null || data['code'] != 0) {
        return _holidayFallback(local, apiFailed: true);
      }
      final type = data['type'] as Map<String, dynamic>?;
      final typeEnum = type?['type'] as int?;
      // 0 工作日 1 周末 2 法定节假日 3 调休补班
      final holiday = data['holiday'] as Map<String, dynamic>?;
      final isStatutoryOff =
          typeEnum == 2 && (holiday?['holiday'] == true);
      final isMakeupWorkday = typeEnum == 3;
      final isWorkday = typeEnum == 0 ||
          isMakeupWorkday ||
          (typeEnum == 2 && holiday?['holiday'] != true);
      String? displayName;
      if (isStatutoryOff) {
        displayName = (holiday?['name'] as String?)?.trim();
        displayName = (displayName != null && displayName.isNotEmpty)
            ? displayName
            : (type?['name'] as String?)?.trim();
      } else if (isMakeupWorkday) {
        displayName = (type?['name'] as String?)?.trim();
      }
      return (isWorkday: isWorkday, name: displayName, apiFailed: false);
    } catch (_) {
      return _holidayFallback(local, apiFailed: true);
    }
  }

  static ({bool isWorkday, String? name, bool apiFailed}) _holidayFallback(
    DateTime local, {
    required bool apiFailed,
  }) {
    final weekend =
        local.weekday == DateTime.saturday || local.weekday == DateTime.sunday;
    return (isWorkday: !weekend, name: null, apiFailed: apiFailed);
  }

  static Future<
      ({
        bool ok,
        double tempC,
        String description,
        String locationHint,
        bool fromLastKnown,
        DateTime? fixTime,
      })?> _loadWeather() async {
    if (kIsWeb) {
      return _openMeteoForecast(
        39.9042,
        116.4074,
        '默认北京（Web 端）',
        fromLastKnown: false,
        fixTime: null,
      );
    }
    final resolved = await _resolveDeviceCoordinates();
    return _openMeteoForecast(
      resolved.lat,
      resolved.lng,
      resolved.hint,
      fromLastKnown: resolved.fromLastKnown,
      fixTime: resolved.fixTime,
    );
  }

  /// 尽量拿到真实坐标；失败时用北京并给出可读原因（与「应用内已授权」不是同一概念）。
  static Future<
      ({
        double lat,
        double lng,
        String hint,
        bool fromLastKnown,
        DateTime? fixTime,
      })> _resolveDeviceCoordinates() async {
    const fallbackLat = 39.9042;
    const fallbackLng = 116.4074;

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return (
          lat: fallbackLat,
          lng: fallbackLng,
          hint: '默认北京（未授权定位）',
          fromLastKnown: false,
          fixTime: null,
        );
      }

      final servicesOn = await Geolocator.isLocationServiceEnabled();
      if (!servicesOn) {
        return (
          lat: fallbackLat,
          lng: fallbackLng,
          hint: '默认北京（系统定位/GPS 总开关未开）',
          fromLastKnown: false,
          fixTime: null,
        );
      }

      // 无 Google Play 服务的小米等机型上 Fused 常不可用，优先走系统 LocationManager。
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 22),
              forceLocationManager: true,
            ),
          );
          return (
            lat: pos.latitude,
            lng: pos.longitude,
            hint: '当前位置附近',
            fromLastKnown: false,
            fixTime: pos.timestamp,
          );
        } on TimeoutException {
          if (kDebugMode) {
            debugPrint('getCurrentPosition (LocationManager): TimeoutException');
          }
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('getCurrentPosition (LocationManager): $e\n$st');
          }
        }
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 25),
          ),
        );
        return (
          lat: pos.latitude,
          lng: pos.longitude,
          hint: '当前位置附近',
          fromLastKnown: false,
          fixTime: pos.timestamp,
        );
      } on TimeoutException {
        if (kDebugMode) {
          debugPrint('getCurrentPosition (Fused): TimeoutException');
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('getCurrentPosition (Fused): $e\n$st');
        }
      }

      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null &&
            last.latitude.abs() > 1e-6 &&
            last.longitude.abs() > 1e-6) {
          return (
            lat: last.latitude,
            lng: last.longitude,
            hint: RecommendationDayContext.lastKnownBackendHint,
            fromLastKnown: true,
            fixTime: last.timestamp,
          );
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('getLastKnownPosition: $e\n$st');
        }
      }

      return (
        lat: fallbackLat,
        lng: fallbackLng,
        hint: '默认北京（实时定位超时或不可用，可开 GPS 到室外再试）',
        fromLastKnown: false,
        fixTime: null,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('RecommendationDayContextLoader._resolveDeviceCoordinates: $e\n$st');
      }
      return (
        lat: fallbackLat,
        lng: fallbackLng,
        hint: '默认北京（定位异常）',
        fromLastKnown: false,
        fixTime: null,
      );
    }
  }

  static Future<
      ({
        bool ok,
        double tempC,
        String description,
        String locationHint,
        bool fromLastKnown,
        DateTime? fixTime,
      })?> _openMeteoForecast(
    double lat,
    double lng,
    String hint, {
    required bool fromLastKnown,
    DateTime? fixTime,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: <String, dynamic>{
          'latitude': lat,
          'longitude': lng,
          'current': 'temperature_2m,weather_code',
          'timezone': 'auto',
        },
      );
      final data = res.data;
      final current = data?['current'] as Map<String, dynamic>?;
      if (current == null) {
        return null;
      }
      final t = (current['temperature_2m'] as num?)?.toDouble();
      final code = (current['weather_code'] as num?)?.toInt();
      if (t == null || code == null) {
        return null;
      }
      return (
        ok: true,
        tempC: t,
        description: _wmoCodeToZh(code),
        locationHint: hint,
        fromLastKnown: fromLastKnown,
        fixTime: fixTime,
      );
    } catch (_) {
      return null;
    }
  }

  static String _wmoCodeToZh(int code) {
    if (code == 0) return '晴朗';
    if (code <= 3) return '多云';
    if (code <= 48) return '有雾或霾';
    if (code <= 57) return '毛毛雨或冻毛毛雨';
    if (code <= 67) return '有雨';
    if (code <= 77) return '降雪或阵雪';
    if (code <= 82) return '阵雨';
    if (code <= 86) return '阵雪';
    if (code <= 99) return '雷暴或强对流';
    return '天气变化中';
  }
}
