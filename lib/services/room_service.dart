import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'dart:io';

class RoomService {
  static final Dio _dio = ApiClient.instance.dio;

  /* ------------------------------------------------------------------ */
  /* ✅ FULL RESPONSE HELPERS                                             */
  /* ------------------------------------------------------------------ */

  static Map<String, dynamic> _headersToMap(Headers h) {
    final out = <String, dynamic>{};
    h.map.forEach((k, v) => out[k] = v);
    return out;
  }

  static Map<String, dynamic> _requestToMap(RequestOptions ro) {
    return {
      "method": ro.method,
      "url": ro.uri.toString(),
      "baseUrl": ro.baseUrl,
      "path": ro.path,
      "queryParameters": ro.queryParameters,
      "contentType": ro.contentType?.toString(),
      "responseType": ro.responseType.toString(),
      "followRedirects": ro.followRedirects,
      "connectTimeout": ro.connectTimeout?.inMilliseconds,
      "receiveTimeout": ro.receiveTimeout?.inMilliseconds,
      "dataType": ro.data?.runtimeType.toString(),
      "extra": ro.extra,
    };
  }

  static Map<String, dynamic> _responseToFullMap(Response r) {
    return {
      "ok": (r.statusCode ?? 0) >= 200 && (r.statusCode ?? 0) < 300,
      "statusCode": r.statusCode,
      "statusMessage": r.statusMessage,
      "headers": _headersToMap(r.headers),
      "isRedirect": r.isRedirect,
      "redirects": r.redirects.map((x) => x.location.toString()).toList(),
      "request": _requestToMap(r.requestOptions),
      "dataType": r.data?.runtimeType.toString(),
      "data": r.data,
    };
  }

  static Map<String, dynamic> _dioErrorToFullMap(DioException e) {
    return {
      "type": e.type.toString(),
      "message": e.message,
      "error": e.error?.toString(),
      "request": _requestToMap(e.requestOptions),
      "response": e.response == null ? null : _responseToFullMap(e.response!),
    };
  }

  static void _prettyPrint(String title, dynamic obj) {
    try {
      final s = const JsonEncoder.withIndent("  ").convert(obj);
      // ignore: avoid_print
      print("🔵 $title\n$s");
    } catch (_) {
      // ignore: avoid_print
      print("🔵 $title\n$obj");
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ GET SUGGESTIONS                                                   */
  /* ------------------------------------------------------------------ */

  static Future<List<dynamic>> getSuggestions(String query) async {
    try {
      print('🔍 Getting suggestions for: $query');
      final response = await _dio.get(
        API.SUGGEST,
        queryParameters: {'q': query},
      );

      // ✅ FULL response dump
      _prettyPrint("SUGGEST FULL RESPONSE", _responseToFullMap(response));

      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data;
        if (data.containsKey('suggestions')) {
          final suggestions = data['suggestions'];
          return suggestions is List ? suggestions : [];
        }
        return [data];
      }

      return response.data is List ? response.data : [response.data];
    } on DioException catch (e) {
      _prettyPrint("SUGGEST DIO ERROR", _dioErrorToFullMap(e));
      rethrow;
    } catch (error) {
      print('❌ Suggestions API Error: $error');
      rethrow;
    }
  }
  /* ------------------------------------------------------------------ */
  /* ✅ CREATE ROOM                                                       */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> createRoom(
    Map<String, dynamic> payload,
    String accessToken,
  ) async {
    print('🛰️ CreateRoom → payload: $payload');

    try {
      final response = await _dio.post(
        API.CREATE_ROOM,
        data: json.encode(payload),
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      // ✅ FULL response dump
      _prettyPrint("CREATE ROOM FULL RESPONSE", _responseToFullMap(response));

      print('🌟 CreateRoom → status: ${response.statusCode}');
      print('🌟 CreateRoom → data type: ${response.data.runtimeType}');
      print('🌟 CreateRoom → data: ${response.data}');

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'CreateRoom failed with status ${response.statusCode}',
        );
      }

      // Ensure we return a Map
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String) {
        // If it's a string, try to parse it
        try {
          return json.decode(response.data) as Map<String, dynamic>;
        } catch (e) {
          // If parsing fails, return as a simple map
          return {'raw': response.data};
        }
      } else {
        // For any other type
        return {'data': response.data};
      }
    } on DioException catch (error) {
      _prettyPrint("CREATE ROOM DIO ERROR", _dioErrorToFullMap(error));

      print('❌ CreateRoom DioError: ${error.message}');
      if (error.response != null) {
        print('❌ CreateRoom Response: ${error.response?.data}');
      }
      rethrow;
    } catch (error) {
      print('❌ CreateRoom Unknown Error: $error');
      rethrow;
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ UPDATE ROOM                                                       */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> updateRoom(
    String roomId,
    Map<String, dynamic> payload,
    String accessToken,
  ) async {
    if (roomId.isEmpty) {
      throw Exception('updateRoom: roomId is required but missing');
    }

    print('🛰️ updateRoom → roomId: $roomId');
    print('🛰️ updateRoom → payload: $payload');

    final url = API.getUpdateRoomUrl(roomId);
    print('🛰️ updateRoom → URL: $url');

    try {
      final response = await _dio.patch(
        url,
        data: json.encode(payload),
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      // ✅ FULL response dump
      _prettyPrint("UPDATE ROOM FULL RESPONSE", _responseToFullMap(response));

      print('🌟 updateRoom → status: ${response.statusCode}');
      print('🌟 updateRoom → data: ${response.data}');

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'updateRoom failed with status ${response.statusCode}',
        );
      }

      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } on DioException catch (error) {
      _prettyPrint("UPDATE ROOM DIO ERROR", _dioErrorToFullMap(error));

      print('❌ updateRoom DioError: ${error.message}');
      if (error.response != null) {
        print('❌ updateRoom Response: ${error.response?.data}');
      }
      rethrow;
    } catch (error) {
      print('❌ updateRoom Unknown Error: $error');
      rethrow;
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ UPLOAD FILES (parallel supported)                                 */
  /* ------------------------------------------------------------------ */

  static Future<List<Map<String, dynamic>>> uploadFiles({
    required List<Map<String, dynamic>> files,
    required String roomId,
    required String accessToken,
    Function(double, int)? onProgress,
  }) async {
    if (roomId.isEmpty) {
      throw Exception('uploadFiles: roomId is required but missing');
    }

    print('📤 uploadFiles → roomId: $roomId, total files: ${files.length}');

    final List<Future<Map<String, dynamic>?>> uploadFutures = [];

    for (int index = 0; index < files.length; index++) {
      final file = files[index];
      final kind = file['kind'] as String;
      final filePath = file['filePath'] as String;

      uploadFutures.add(
        _uploadSingleFile(
          kind: kind,
          filePath: filePath,
          roomId: roomId,
          accessToken: accessToken,
          index: index,
          onProgress: onProgress,
        ),
      );
    }

    final results = await Future.wait(uploadFutures, eagerError: false);
    final successfulUploads = results
        .whereType<Map<String, dynamic>>()
        .toList();

    if (successfulUploads.isEmpty) {
      throw Exception('All uploads failed');
    }

    return successfulUploads;
  }

  static Future<Map<String, dynamic>?> _uploadSingleFile({
    required String kind,
    required String filePath,
    required String roomId,
    required String accessToken,
    required int index,
    Function(double, int)? onProgress,
  }) async {
    try {
      final isVideo = kind == 'video';

      final endpointPath = isVideo
          ? API.getRoomVideoUrl(roomId)
          : API.getRoomImagesUrl(roomId);

      final endpoint = _absolutizeUrl(endpointPath);

      final fileExt = filePath.split('.').last.toLowerCase();

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename:
              'upload_${DateTime.now().millisecondsSinceEpoch}_$index.$fileExt',
        ),
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = (sent / total) * 100;
            onProgress?.call(progress, index);
          }
        },
      );

      // ✅ FULL response dump
      _prettyPrint(
        "UPLOAD ($kind) FULL RESPONSE",
        _responseToFullMap(response),
      );

      final data = response.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      dynamic item;

      if (isVideo) {
        item =
            data['video'] ??
            data['item']?['video'] ??
            (data['items'] is List && data['items'].isNotEmpty
                ? data['items'][0]['video']
                : data);
      } else {
        item =
            data['image'] ??
            data['item'] ??
            (data['items'] is List && data['items'].isNotEmpty
                ? data['items'][0]
                : data);
      }

      if (item == null || item is! Map) return null;

      final mediaObj = Map<String, dynamic>.from(item);

      final rawUrl =
          mediaObj['url'] ??
          mediaObj['image_url'] ??
          mediaObj['video_url'] ??
          mediaObj['file_url'] ??
          mediaObj['location'] ??
          mediaObj['path'] ??
          '';

      if (rawUrl.toString().isEmpty) return null;

      return {
        ...mediaObj,
        'url': _absolutizeUrl(rawUrl.toString()),
        'kind': kind,
        'index': index,
        'success': true,
      };
    } on DioException catch (e) {
      _prettyPrint("UPLOAD ($kind) DIO ERROR", _dioErrorToFullMap(e));
      return null;
    } catch (e) {
      print('❌ File $index upload failed: $e');
      return null;
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ PATCH ROOM IMAGE                                                  */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> patchRoomImage({
    required String roomId,
    required String mediaId,
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    if (roomId.isEmpty) {
      throw Exception('patchRoomImage: roomId is required');
    }
    if (mediaId.isEmpty) {
      throw Exception('patchRoomImage: mediaId is required');
    }

    print('🛰️ patchRoomImage → roomId: $roomId');
    print('🖼️ patchRoomImage → mediaId: $mediaId');
    print('📦 patchRoomImage → payload: $payload');

    final url = API.getRoomImageByIdUrl(roomId, mediaId);
    print('🛰️ patchRoomImage → URL: $url');

    try {
      final response = await _dio.patch(
        url,
        data: json.encode(payload),
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      // ✅ FULL response dump
      _prettyPrint(
        "PATCH ROOM IMAGE FULL RESPONSE",
        _responseToFullMap(response),
      );

      print('🌟 patchRoomImage → status: ${response.statusCode}');
      print('🌟 patchRoomImage → data: ${response.data}');

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'patchRoomImage failed with status ${response.statusCode}',
        );
      }

      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } on DioException catch (error) {
      _prettyPrint("PATCH ROOM IMAGE DIO ERROR", _dioErrorToFullMap(error));

      print('❌ patchRoomImage DioError: ${error.message}');
      if (error.response != null) {
        print('❌ patchRoomImage Response: ${error.response?.data}');
      }
      rethrow;
    } catch (error) {
      print('❌ patchRoomImage Unknown Error: $error');
      rethrow;
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ FETCH ROOMS                                                       */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> fetchRooms({
    String sort = 'distance',
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        API.CREATE_ROOM,
        queryParameters: {'sort': sort, 'offset': offset, 'limit': limit},
      );

      // ✅ FULL response dump
      _prettyPrint("FETCH ROOMS FULL RESPONSE", _responseToFullMap(response));

      print('🏠 fetchRooms → status: ${response.statusCode}');
      print('🏠 fetchRooms → raw data: ${response.data}');

      final payload = response.data is Map<String, dynamic>
          ? response.data
          : {'items': response.data is List ? response.data : []};

      final items = payload['items'] is List ? payload['items'] as List : [];

      final normalizedItems = items.map<Map<String, dynamic>>((item) {
        final itemMap = item is Map<String, dynamic>
            ? item
            : (item is Map
                  ? Map<String, dynamic>.from(item)
                  : <String, dynamic>{});

        final images =
            (itemMap['images'] is List && (itemMap['images'] as List).isNotEmpty
            ? (itemMap['images'] as List).map<Map<String, dynamic>>((img) {
                final imgMap = img is Map<String, dynamic>
                    ? img
                    : (img is Map
                          ? Map<String, dynamic>.from(img)
                          : <String, dynamic>{});

                final rawUrl =
                    imgMap['url'] ??
                    imgMap['image_url'] ??
                    imgMap['file_url'] ??
                    imgMap['location'] ??
                    imgMap['path'] ??
                    '';

                final url = rawUrl.toString().isNotEmpty
                    ? _absolutizeUrl(rawUrl.toString())
                    : '';

                return {
                  'media_id': imgMap['media_id'],
                  'url': url,
                  'uri': url,
                  'key': imgMap['key'],
                  'meta': imgMap['meta'],
                };
              }).toList()
            : []);

        return {
          'id': itemMap['room_id'],
          'title': itemMap['title'],
          'description': itemMap['description'],
          'rent': itemMap['rent'],
          'deposit': itemMap['deposit'],
          'availability_from': itemMap['availability_from'],
          'bedrooms': itemMap['bedrooms_count'],
          'bedrooms_label': itemMap['bedrooms_label'],
          'sqft_area': itemMap['sqft_area'],
          'furnished_type': itemMap['furnished_type'],
          'floor': itemMap['floor'],
          'living_preference': itemMap['living_preference'],
          'tenant_preferences': itemMap['tenant_preferences'] is List
              ? itemMap['tenant_preferences'] as List
              : [],
          'amenities': itemMap['amenities'] is List
              ? itemMap['amenities'] as List
              : [],
          'rules': itemMap['rules'] is List ? itemMap['rules'] as List : [],
          'location_address': itemMap['location_address'],
          'location_lat': itemMap['location_lat'],
          'location_long': itemMap['location_long'],
          'area': itemMap['area'],
          'city': itemMap['city'],
          'images': images,
          'published': itemMap['status'] == 'ACTIVE',
          'raw': itemMap,
        };
      }).toList();

      return {
        'items': normalizedItems,
        'total': payload['total'] ?? normalizedItems.length,
        'city': payload['city'],
        'center_lat': payload['center_lat'],
        'center_lng': payload['center_lng'],
        'facets': payload['facets'] is Map ? payload['facets'] as Map : {},
        'raw': payload,
      };
    } on DioException catch (error) {
      _prettyPrint("FETCH ROOMS DIO ERROR", _dioErrorToFullMap(error));

      print('❌ fetchRooms DioError: ${error.message}');
      if (error.response != null) {
        print('❌ fetchRooms Response: ${error.response?.data}');
      }
      rethrow;
    } catch (error) {
      print('❌ fetchRooms Unknown Error: $error');
      rethrow;
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ DELETE ROOM                                                       */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> deleteRoom(
    String roomId,
    String accessToken,
  ) async {
    if (roomId.isEmpty) {
      throw Exception('deleteRoom: roomId is required');
    }

    print('🛰️ deleteRoom → roomId: $roomId');

    final url = API.getDeleteRoomUrl(roomId);
    print('🛰️ deleteRoom → URL: $url');

    try {
      final response = await _dio.delete(
        url,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      // ✅ FULL response dump
      _prettyPrint("DELETE ROOM FULL RESPONSE", _responseToFullMap(response));

      print('🌟 deleteRoom → status: ${response.statusCode}');
      print('🌟 deleteRoom → data: ${response.data}');

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'deleteRoom failed with status ${response.statusCode}',
        );
      }

      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } on DioException catch (error) {
      _prettyPrint("DELETE ROOM DIO ERROR", _dioErrorToFullMap(error));

      print('❌ deleteRoom DioError: ${error.message}');
      if (error.response != null) {
        print('❌ deleteRoom Response: ${error.response?.data}');
      }
      rethrow;
    } catch (error) {
      print('❌ deleteRoom Unknown Error: $error');
      rethrow;
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ DELETE ROOM IMAGE                                                 */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> deleteRoomImage({
    required String roomId,
    required String mediaId,
    required String accessToken,
  }) async {
    if (roomId.isEmpty) {
      throw Exception('deleteRoomImage: roomId is required');
    }
    if (mediaId.isEmpty) {
      throw Exception('deleteRoomImage: mediaId is required');
    }

    print('🗑️ deleteRoomImage → roomId: $roomId, mediaId: $mediaId');

    final url = API.getDeleteRoomImageUrl(roomId, mediaId);
    print('🗑️ deleteRoomImage → URL: $url');

    try {
      final response = await _dio.delete(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      // ✅ FULL response dump
      _prettyPrint(
        "DELETE ROOM IMAGE FULL RESPONSE",
        _responseToFullMap(response),
      );

      print('🌟 deleteRoomImage → status: ${response.statusCode}');
      print('🌟 deleteRoomImage → data: ${response.data}');

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'deleteRoomImage failed with status ${response.statusCode}',
        );
      }

      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } on DioException catch (error) {
      _prettyPrint("DELETE ROOM IMAGE DIO ERROR", _dioErrorToFullMap(error));

      print('❌ deleteRoomImage DioError: ${error.message}');
      if (error.response != null) {
        print('❌ deleteRoomImage Response: ${error.response?.data}');
      }
      rethrow;
    } catch (error) {
      print('❌ deleteRoomImage Unknown Error: $error');
      rethrow;
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ DELETE ROOM VIDEO                                                 */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> deleteRoomVideo({
    required String roomId,
    required String accessToken,
  }) async {
    if (roomId.isEmpty) {
      throw Exception('deleteRoomVideo: roomId is required');
    }

    print('🗑️ deleteRoomVideo → roomId: $roomId');

    final url = API.getDeleteRoomVideoUrl(roomId);
    print('🗑️ deleteRoomVideo → URL: $url');

    try {
      final response = await _dio.delete(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      // ✅ FULL response dump
      _prettyPrint(
        "DELETE ROOM VIDEO FULL RESPONSE",
        _responseToFullMap(response),
      );

      print('🌟 deleteRoomVideo → status: ${response.statusCode}');
      print('🌟 deleteRoomVideo → data: ${response.data}');

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'deleteRoomVideo failed with status ${response.statusCode}',
        );
      }

      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } on DioException catch (error) {
      _prettyPrint("DELETE ROOM VIDEO DIO ERROR", _dioErrorToFullMap(error));

      print('❌ deleteRoomVideo DioError: ${error.message}');
      if (error.response != null) {
        print('❌ deleteRoomVideo Response: ${error.response?.data}');
      }
      rethrow;
    } catch (error) {
      print('❌ deleteRoomVideo Unknown Error: $error');
      rethrow;
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ PRIVATE HELPER: ABSOLUTIZE URL                                     */
  /* ------------------------------------------------------------------ */
  static Future<Map<String, dynamic>> getMe({
    required String accessToken,
  }) async {
    try {
      final res = await _dio.get(
        API.USER_ME,
        options: Options(
          headers: {
            "Authorization": "Bearer $accessToken",
            "Accept": "application/json",
          },
        ),
      );

      final data = res.data;

      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      if (data is String) {
        final decoded = json.decode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }

      throw Exception("Invalid /users/me response format");
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? "User API error";
      throw Exception(msg);
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ UPLOAD AVATAR (Profile Picture)                                 */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> uploadAvatar({
    required File imageFile, // ✅ अब File class available होगी
    required String accessToken,
    Function(double)? onProgress,
  }) async {
    try {
      print('📤 UPLOAD AVATAR STARTED');
      print('   File path: ${imageFile.path}');
      print('   File size: ${await imageFile.length()} bytes');
      print('   File exists: ${await imageFile.exists()}');

      // Create FormData
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // Print formData details
      print('📦 FormData created');
      print('   Fields: ${formData.fields.length}');
      print('   Files: ${formData.files.length}');

      // Make API call to /users/me/avatar
      final response = await _dio.post(
        API.USER_AVATAR, // Avatar upload endpoint
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            final progress = (sent / total) * 100;
            onProgress(progress);
            print('📊 Upload progress: ${progress.toStringAsFixed(2)}%');
          }
        },
      );

      // ✅ FULL response dump
      _prettyPrint("UPLOAD AVATAR FULL RESPONSE", _responseToFullMap(response));

      print('✅ Avatar upload successful!');
      print('   Status: ${response.statusCode}');
      print('   Response data: ${response.data}');

      // Process response
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;

        // Extract profile image URL and key
        final profileImageUrl = data['profile_image_url'] ?? '';
        final profileImageKey = data['profile_image_key'] ?? '';

        print('📸 Extracted from response:');
        print('   Profile Image URL: $profileImageUrl');
        print('   Profile Image Key: $profileImageKey');

        // Convert relative URL to absolute URL if needed
        final absoluteUrl = _absolutizeUrl(profileImageUrl);

        return {
          'success': true,
          'profile_image_url': absoluteUrl,
          'profile_image_key': profileImageKey,
          'full_response': data,
          'status_code': response.statusCode,
        };
      } else {
        print('⚠️ Avatar upload response is not a Map');
        return {
          'success': true,
          'raw_response': response.data,
          'status_code': response.statusCode,
        };
      }
    } on DioException catch (e) {
      _prettyPrint("UPLOAD AVATAR DIO ERROR", _dioErrorToFullMap(e));

      print('❌ Avatar upload failed with DioException');
      print('   Error type: ${e.type}');
      print('   Error message: ${e.message}');

      if (e.response != null) {
        print('   Response status: ${e.response?.statusCode}');
        print('   Response data: ${e.response?.data}');
      }

      return {
        'success': false,
        'error': 'DioException',
        'message': e.message ?? 'Unknown Dio error',
        'response_data': e.response?.data,
        'status_code': e.response?.statusCode,
      };
    } catch (e) {
      print('❌ Avatar upload failed with unknown error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: ${e.toString()}');

      return {
        'success': false,
        'error': 'UnknownError',
        'message': e.toString(),
      };
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ GET USER ME                                                      */
  /* ------------------------------------------------------------------ */
  static Future<Map<String, dynamic>> deleteAvatar({
    required String accessToken,
  }) async {
    try {
      print('🗑️ DELETE AVATAR STARTED');

      // Make API call to DELETE /users/me/avatar
      final response = await _dio.delete(
        API.USER_AVATAR, // Same endpoint as upload, but DELETE method
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      // ✅ FULL response dump
      _prettyPrint("DELETE AVATAR FULL RESPONSE", _responseToFullMap(response));

      print('✅ Avatar delete successful!');
      print('   Status: ${response.statusCode}');
      print('   Response data: ${response.data}');

      // Process response
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Delete avatar failed with status ${response.statusCode}',
        );
      }

      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'message': 'Avatar deleted successfully',
          'data': data,
          'status_code': response.statusCode,
        };
      } else {
        return {
          'success': true,
          'message': 'Avatar deleted successfully',
          'raw_response': response.data,
          'status_code': response.statusCode,
        };
      }
    } on DioException catch (e) {
      _prettyPrint("DELETE AVATAR DIO ERROR", _dioErrorToFullMap(e));

      print('❌ Avatar delete failed with DioException');
      print('   Error type: ${e.type}');
      print('   Error message: ${e.message}');

      if (e.response != null) {
        print('   Response status: ${e.response?.statusCode}');
        print('   Response data: ${e.response?.data}');
      }

      return {
        'success': false,
        'error': 'DioException',
        'message': e.message ?? 'Unknown Dio error',
        'response_data': e.response?.data,
        'status_code': e.response?.statusCode,
      };
    } catch (e) {
      print('❌ Avatar delete failed with unknown error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: ${e.toString()}');

      return {
        'success': false,
        'error': 'UnknownError',
        'message': e.toString(),
      };
    }
  }

  /* ------------------------------------------------------------------ */
  /* ✅ FETCH OWNER ROOMS (NEW)                                          */
  /* ------------------------------------------------------------------ */

  static Future<Map<String, dynamic>> fetchOwnerRooms({
    required String accessToken,
    bool includeDeleted = false,
    String sort = "recent",
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        API.OWNER_ROOMS,
        queryParameters: {
          "include_deleted": includeDeleted,
          "sort": sort,
          "offset": offset,
          "limit": limit,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $accessToken",
            "Accept": "application/json",
          },
        ),
      );

      // ✅ FULL response dump
      _prettyPrint(
        "FETCH OWNER ROOMS FULL RESPONSE",
        _responseToFullMap(response),
      );

      final payload = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data is Map
                ? Map<String, dynamic>.from(response.data as Map)
                : <String, dynamic>{});

      final items = payload["items"] is List
          ? (payload["items"] as List)
          : const [];

      // ✅ Normalize to your UI shape
      final normalizedItems = items.map<Map<String, dynamic>>((item) {
        final m = item is Map<String, dynamic>
            ? item
            : (item is Map
                  ? Map<String, dynamic>.from(item)
                  : <String, dynamic>{});

        // images
        final imgs = (m["images"] is List)
            ? (m["images"] as List).map<Map<String, dynamic>>((img) {
                final im = img is Map<String, dynamic>
                    ? img
                    : (img is Map
                          ? Map<String, dynamic>.from(img)
                          : <String, dynamic>{});

                final rawUrl =
                    (im["url"] ??
                            im["image_url"] ??
                            im["file_url"] ??
                            im["location"] ??
                            im["path"] ??
                            "")
                        .toString();

                final absUrl = rawUrl.isNotEmpty ? _absolutizeUrl(rawUrl) : "";

                return {
                  "media_id": im["media_id"],
                  "url": absUrl,
                  "key": im["key"],
                  "meta": im["meta"],
                };
              }).toList()
            : <Map<String, dynamic>>[];

        // videos (if backend returns)
        final vids = (m["videos"] is List)
            ? (m["videos"] as List).map<Map<String, dynamic>>((vid) {
                final vm = vid is Map<String, dynamic>
                    ? vid
                    : (vid is Map
                          ? Map<String, dynamic>.from(vid)
                          : <String, dynamic>{});

                final rawUrl =
                    (vm["url"] ??
                            vm["video_url"] ??
                            vm["file_url"] ??
                            vm["location"] ??
                            vm["path"] ??
                            "")
                        .toString();

                final absUrl = rawUrl.isNotEmpty ? _absolutizeUrl(rawUrl) : "";

                return {
                  "media_id": vm["media_id"],
                  "url": absUrl,
                  "key": vm["key"],
                  "meta": vm["meta"],
                };
              }).toList()
            : <Map<String, dynamic>>[];

        // ✅ combine media urls for UI carousel
        final media = <String>[
          ...imgs
              .map((x) => (x["url"] ?? "").toString())
              .where((u) => u.isNotEmpty),
          ...vids
              .map((x) => (x["url"] ?? "").toString())
              .where((u) => u.isNotEmpty),
        ];

        return {
          "id": (m["room_id"] ?? "").toString(),
          "title": (m["title"] ?? "").toString(),
          "description": m["description"]?.toString(),
          "rent": m["rent"] ?? 0,
          "deposit": m["deposit"] ?? 0,
          "availability_from": m["availability_from"]?.toString(),
          "bedrooms": m["bedrooms_count"],
          "sqft_area": m["sqft_area"],
          "furnished_type": m["furnished_type"]?.toString(),
          "floor": m["floor"],
          "tenant_preferences": (m["tenant_preferences"] is List)
              ? (m["tenant_preferences"] as List)
              : [],
          "amenities": (m["amenities"] is List) ? (m["amenities"] as List) : [],
          "rules": (m["rules"] is List) ? (m["rules"] as List) : [],
          "location_address": m["location_address"]?.toString(),
          "area": m["area"]?.toString(),
          "city": m["city"]?.toString(),
          "published": (m["status"]?.toString() == "ACTIVE"),
          "media": media,
          "raw": m,
        };
      }).toList();

      return {
        "total": payload["total"] ?? normalizedItems.length,
        "items": normalizedItems,
        "raw": payload,
      };
    } on DioException catch (e) {
      _prettyPrint("FETCH OWNER ROOMS DIO ERROR", _dioErrorToFullMap(e));
      rethrow;
    }
  }

  static String _absolutizeUrl(String url) {
    if (url.isEmpty) return '';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final baseUrl = API.BASE_URL;
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    } else {
      return '$baseUrl/$url';
    }
  }
}
