// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockTypeAdapter extends TypeAdapter<StockType> {
  @override
  final int typeId = 14;

  @override
  StockType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 1:
        return StockType.none;
      case 2:
        return StockType.basicMaterials;
      case 3:
        return StockType.communicationServices;
      case 4:
        return StockType.consumerDiscretionary;
      case 5:
        return StockType.consumerStaples;
      case 6:
        return StockType.energy;
      case 7:
        return StockType.financial;
      case 8:
        return StockType.healthcare;
      case 9:
        return StockType.industrials;
      case 10:
        return StockType.realEstate;
      case 11:
        return StockType.technology;
      case 12:
        return StockType.utilities;
      default:
        return StockType.none;
    }
  }

  @override
  void write(BinaryWriter writer, StockType obj) {
    switch (obj) {
      case StockType.none:
        writer.writeByte(1);
        break;
      case StockType.basicMaterials:
        writer.writeByte(2);
        break;
      case StockType.communicationServices:
        writer.writeByte(3);
        break;
      case StockType.consumerDiscretionary:
        writer.writeByte(4);
        break;
      case StockType.consumerStaples:
        writer.writeByte(5);
        break;
      case StockType.energy:
        writer.writeByte(6);
        break;
      case StockType.financial:
        writer.writeByte(7);
        break;
      case StockType.healthcare:
        writer.writeByte(8);
        break;
      case StockType.industrials:
        writer.writeByte(9);
        break;
      case StockType.realEstate:
        writer.writeByte(10);
        break;
      case StockType.technology:
        writer.writeByte(11);
        break;
      case StockType.utilities:
        writer.writeByte(12);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
