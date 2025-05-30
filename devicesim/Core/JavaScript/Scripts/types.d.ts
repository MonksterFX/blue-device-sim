export interface TypeDefinition {
  name: string;
  size: number;
  encode: (value: any) => ArrayBuffer;
  decode: (buffer: ArrayBuffer, offset: number) => any;
  validate: (value: any) => boolean;
}

export class ArrayBufferError extends Error {
  constructor(message: string);
}

export class ValidationError extends ArrayBufferError {
  constructor(message: string);
}

export class BufferError extends ArrayBufferError {
  constructor(message: string);
}

export class ArrayBufferEncoder {
  encode(data: any[], types: TypeDefinition[]): ArrayBuffer;
}

export class ArrayBufferDecoder {
  decode(buffer: ArrayBuffer, types: TypeDefinition[]): any[];
}

export interface Types {
  Uint8: TypeDefinition;
  Uint16: TypeDefinition;
  Uint32: TypeDefinition;
  Int8: TypeDefinition;
  Int16: TypeDefinition;
  Int32: TypeDefinition;
  Float32: TypeDefinition;
  Double: TypeDefinition;
  Boolean: TypeDefinition;
  String: (length: number) => TypeDefinition;
  Endian: (baseType: TypeDefinition, endianness: 'little' | 'big') => TypeDefinition;
}

export const types: Types; 