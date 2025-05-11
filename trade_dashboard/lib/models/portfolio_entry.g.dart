// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PortfolioEntryAdapter extends TypeAdapter<PortfolioEntry> {
  @override
  final int typeId = 16;

  @override
  PortfolioEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortfolioEntry(
      updatedAt: (fields[4] as List).cast<DateTime>(),
      stock: fields[1] as Stock,
      numShares: fields[2] as double,
      transactions: (fields[3] as List).cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(1)
      ..write(obj.stock)
      ..writeByte(2)
      ..write(obj.numShares)
      ..writeByte(3)
      ..write(obj.transactions)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
