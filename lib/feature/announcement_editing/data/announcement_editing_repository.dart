import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:map_kit_interface/map_kit.dart';
import 'package:smart/feature/announcement_editing/data/models/edit_data.dart';
import 'package:smart/feature/announcement_editing/data/models/image_data.dart';
import 'package:smart/feature/announcement_editing/data/images.dart';
import 'package:smart/feature/create_announcement/data/models/car_filter.dart';
import 'package:smart/feature/create_announcement/data/models/marks_filter.dart';
import 'package:smart/models/announcement.dart';
import 'package:smart/models/item/item.dart';
import 'package:smart/models/item/subcategory_filters.dart';
import 'package:smart/services/database/database_service.dart';
import 'package:smart/services/storage_service.dart';
import 'package:smart/utils/constants.dart';
import 'package:smart/utils/price_type.dart';

class AnnouncementEditingRepository {
  final DatabaseService _databaseService;
  final FileStorageManager _storageManager;
  final _picker = ImagePicker();

  AnnouncementEditingRepository(DatabaseService databaseService, FileStorageManager storageManager)
      : _databaseService = databaseService,
        _storageManager = storageManager;

  Announcement? _currentAnnouncement;

  AnnouncementEditData? editData;
  EditImages images = EditImages();

  List<ImageData> get currentImages => images.currentImages;

  void closeEdit() {
    editData = null;
    images.clear();
  }

  Future<void> deleteAnnouncement(String announcementId) =>
      _databaseService.announcements.deleteAnnouncement(announcementId);

  Future<void> setAnnouncementForEdit(Announcement announcement) async {
    _currentAnnouncement = announcement;
    editData = AnnouncementEditData.fromAnnouncement(announcement);

    images.clear();
    await _getCurrentAnnouncementImages();
  }

  void deleteImage(ImageData image) => images.deleteImage(image);

  // void addImage(Uint8List imageAsBytes) => images.addImage(imageAsBytes);

  void setTitle(String newValue) => editData!.title = newValue;

  void setPlace(CityDistrict newPlace) {
    editData!.cityId = newPlace.cityId;
    editData!.areaId = newPlace.id;
  }

  void setCustomCoordinate(CommonLatLng newLatLng) {
    editData!.longitude = newLatLng.longitude;
    editData!.latitude = newLatLng.latitude;
  }

  void setParameters({
    required List<Parameter> newParameters,
    required CarFilter? carFilter,
    required MarksFilter? marksFilter,
    required SubcategoryFilters? subcategoryFilters,
  }) {
    final List<Parameter> parameters = [];

    // if (carFilter != null) {
    //   if (subcategoryFilters?.hasMark ?? false) {
    //     parameters.add(
    //       TextParameter(
    //         key: 'car_mark',
    //         arName: 'العلامة التجارية',
    //         frName: 'Marque',
    //         value: carFilter.markTitle,
    //       ),
    //     );
    //   }
    //   if (subcategoryFilters?.hasModel ?? false) {
    //     parameters.add(
    //       TextParameter(
    //         key: 'car_model',
    //         arName: 'نموذج',
    //         frName: 'Modèle',
    //         value: carFilter.modelTitle,
    //       ),
    //     );
    //   }
    // }

    // if (marksFilter != null) {
    //   if (subcategoryFilters?.hasMark ?? false) {
    //     parameters.add(
    //       TextParameter(
    //         key: 'mark',
    //         arName: 'العلامة التجارية',
    //         frName: 'Marque',
    //         value: marksFilter.markTitle,
    //       ),
    //     );
    //   }
    //   if (subcategoryFilters?.hasModel ?? false) {
    //     parameters.add(
    //       TextParameter(
    //         key: 'model',
    //         arName: 'نموذج',
    //         frName: 'Modèle',
    //         value: marksFilter.modelTitle,
    //       ),
    //     );
    //   }
    // }
    parameters.addAll(newParameters);
    editData!.parameters = parameters;
  }

  void setDescription(String newValue) => editData!.description = newValue;

  void setPrice(double newValue) => editData!.price = newValue;
  void setPriceType(PriceType newValue) => editData!.priceType = newValue;

  Future<void> pickImages() async {
    final resImages = await _picker.pickMultiImage();
    for (var im in resImages) {
      images.addImage(await im.readAsBytes());
    }
  }

  Future saveChanges(
    BuildContext context,
    String? newSubcategiryid,
    String? newMarkId,
    String? newModelId,
  ) async {
    await _saveImagesChanges();
    await _saveThumb();
    await _databaseService.announcements.editAnnouncement(
      context: context,
      editData: editData!,
      newSubcategoryid: newSubcategiryid,
      newMarkId: newMarkId,
      newModelId: newModelId,
    );
  }

  Future _saveImagesChanges() async {
    final newImagesUrls = await _uploadNewImages();
    editData!.images.addAll(newImagesUrls);
    await _deleteImages();
  }

  Future _saveThumb() async {
    await _deleteThumb();
    final thumbUrl = await _uploadThumb();
    editData!.thumb = thumbUrl;
  }

  Future<List<String>> _uploadNewImages() async {
    final bytesList = await images.getNewImages();
    final urls = await _storageManager.uploadAnnouncementImages(bytesList);
    return urls;
  }

  Future<String> _uploadThumb() async {
    final bytesList = await images.getThumbImage();
    final url = await _storageManager.uploadThumb(bytesList);
    return url;
  }

  Future<void> _deleteImages() async {
    final deletedIds = images.deletedImages();
    for (String id in deletedIds) {
      final fileUrl = _storageManager.createViewUrl(id, announcementsBucketId);
      editData!.images.remove(fileUrl);
      await _storageManager.deleteImage(id, announcementsBucketId);
    }
  }

  Future<void> _deleteThumb() async {
    final deletedId = images.thumbImage();
    if (deletedId != null) {
      try {
        await _storageManager.deleteImage(deletedId, announcementsBucketId);
      } catch (err) {
        // ignore: avoid_print
        print(err);
      }
    }
  }

  Future _getCurrentAnnouncementImages() async {
    final newImages = <ImageData>[];
    for (var imageUrl in _currentAnnouncement!.images) {
      final String id = getIdFromUrl(imageUrl) ?? imageUrl;
      final Uint8List? bytes = await _databaseService.announcements.getAnnouncementImage(imageUrl);
      if (bytes != null) {
        newImages.add(ImageData(id, bytes));
      }
    }

    late ImageData thumbImage;
    final String thumbUrl = _currentAnnouncement!.thumb;
    final String id = getIdFromUrl(thumbUrl) ?? thumbUrl;
    final Uint8List? bytes = await _databaseService.announcements.getAnnouncementImage(thumbUrl);
    if (bytes != null) {
      thumbImage = ImageData(id, bytes);
    }

    images.addCurrentImages(newImages, thumbImage);
  }
}
