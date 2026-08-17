import 'medicine_model.dart';

class CartItemModel {
  final MedicineModel medicine;
  int quantity;

  CartItemModel({
    required this.medicine,
    this.quantity = 1,
  });
}
