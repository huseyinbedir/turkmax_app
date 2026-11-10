import 'package:equatable/equatable.dart';

/// Telefonla eşleşmiş bir Bluetooth cihazı.
class BondedDevice extends Equatable {
  const BondedDevice({
    required this.name,
    required this.address,
    this.likelyCcu = false,
  });

  /// Test için bellek içi sahte gösterge.
  static const fake = BondedDevice(
    name: 'Sahte CCU',
    address: fakeAddress,
    likelyCcu: true,
  );
  static const fakeAddress = 'fake';

  final String name;
  final String address;

  /// Ad, Yamaha CCU adlandırmasına benziyor (sezgisel).
  final bool likelyCcu;

  bool get isFake => address == fakeAddress;

  @override
  List<Object?> get props => [name, address, likelyCcu];
}
