//Oleg Antipov
//http://www.blog.anegmetex.com

package com.adobe.crypto
{
    public class AgeCrypt 
	{
		import flash.utils.ByteArray;
		
 		//!!!Максимальный размер кодируемого буфера!!!
		private static const MAX_BUFFER_SIZE:uint = 32767;
		
		//Ключ для кодирования\декодирования - в целях безопасности лучше 
		//конечно хранить в другом месте....
        private static var KEY:String = "g6sw6jiuy6ySkN20BHh3367%@)895A65667bn p[SR.[GH";

 
        public static function encode(source:String):String 
		{
			resetEncoder();
            encodeBase64(xor(source));
            return flushEncoder();
        }
 
        public static function decode(source:String):String 
		{
			resetDecoder();
            decodeBase64(source);
            return xor(flushDecoder().toString());
        }
		
		
		//------------XOR Cipher-------------
        private static function xor(source:String):String 
		{
            var key:String = KEY;
            var result:String = new String();
            for(var i:Number = 0; i < source.length; i++) {
                if(i > (key.length - 1)) {
                    key += key;
                }
                result += String.fromCharCode(source.charCodeAt(i) ^ 
											  key.charCodeAt(i));
            }
            return result;
        }
		
		//------------DECODER-------------
	    //переменные декодера
		private static var count:int=0;
		private static var data:ByteArray;
		private static var filled:int=0;
		private static var work:Array=[0, 0, 0, 0];
	
		private static const ESCAPE_CHAR_CODE:Number = 61; // The '=' char
	
		private static const inverse:Array =
		[
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
			52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
			64,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
			15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
			64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
			41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
		];
		
		//дальше методы декодера
		
		//Декодирование строки формата Base64 и добавление результата 
		//во внутренний буфер
		private static function decodeBase64(encoded:String):void
		{
			for (var i:uint = 0; i < encoded.length; ++i)
			{
				var c:Number = encoded.charCodeAt(i);
	
				if (c == ESCAPE_CHAR_CODE)
					work[count++] = -1;
				else if (inverse[c] != 64)
					work[count++] = inverse[c];
				else
					continue;
	
				if (count == 4)
				{
					count = 0;
					data.writeByte((work[0] << 2) | ((work[1] & 0xFF) >> 4));
					filled++;
	
					if (work[2] == -1)
						break;
	
					data.writeByte((work[1] << 4) | ((work[2] & 0xFF) >> 2));
					filled++;
	
					if (work[3] == -1)
						break;
	
					data.writeByte((work[2] << 6) | work[3]);
					filled++;
				}
			}
		}
	
		private static function drainDecoder():ByteArray
		{
			var result:ByteArray = new ByteArray();
			copyByteArray(data, result, filled);
			filled = 0;
			return result;
		}
	
		private static function flushDecoder():ByteArray
		{
			if (count > 0)
			{
				trace("Error in flushDecoder(): partialBlockDropped!");
			}
			return drainDecoder();
		}
	
		//Очистка всех буфферов декодера и приведение его переменных 
		//в начальное состояние
		private static function resetDecoder():void
		{
			data = new ByteArray();
			count = 0;
			filled = 0;
			work[0] = 0;
			work[1] = 0;
			work[2] = 0;
			work[3] = 0;
		}
	
		//Возвращает текущий буфер как массив байт.
		private static function toByteArray():ByteArray
		{
			var result:ByteArray = flushDecoder();
			resetDecoder();
			return result;
		}

		private static function copyByteArray(source:ByteArray, 
											  destination:ByteArray, 
											  length:uint = 0):void
		{
			var oldPosition:int = source.position;
	
			source.position = 0;
			destination.position = 0;
			var i:uint = 0;
	
			while (source.bytesAvailable > 0 && i < length)
			{
				destination.writeByte(source.readByte());
				i++;
			}
	
			source.position = oldPosition;
			destination.position = 0;
		}

		//----------ENCODER------------
		//переменные кодера
		
		private static const CHARSET_UTF_8:String = "UTF-8";
		private static var newLine:int = 10;
		private static var insertNewLines:Boolean = true;
	
		private static var _buffers:Array;
		private static var _count:uint=0;
		private static var _line:uint=0;
		private static var _work:Array = [ 0, 0, 0 ];

		private static const ALPHABET_CHAR_CODES:Array =
		[
			65,   66,  67,  68,  69,  70,  71,  72,
			73,   74,  75,  76,  77,  78,  79,  80,
			81,   82,  83,  84,  85,  86,  87,  88,
			89,   90,  97,  98,  99, 100, 101, 102,
			103, 104, 105, 106, 107, 108, 109, 110,
			111, 112, 113, 114, 115, 116, 117, 118,
			119, 120, 121, 122,  48,  49,  50,  51,
			52,   53,  54,  55,  56,  57,  43,  47
		];
		
		//Дальше методы кодера
		private static function drainEncoder():String
		{
			var result:String = "";
	
			for (var i:uint = 0; i < _buffers.length; i++)
			{
				var buffer:Array = _buffers[i] as Array;
				result += String.fromCharCode.apply(null, buffer);
			}
	
			_buffers = [];
			_buffers.push([]);
	
			return result;
		}
	
		//Кодирование строки формата Base64 и добавление результата 
		//во внешний буфер
		private static function encodeBase64(data:String, 
											 offset:uint=0, 
											 length:uint=0):void
		{
			if (length == 0)
				length = data.length;
	
			var currentIndex:uint = offset;
	
			var endIndex:uint = offset + length;
			if (endIndex > data.length)
				endIndex = data.length;
	
			while (currentIndex < endIndex)
			{
				_work[_count] = data.charCodeAt(currentIndex);
				_count++;
	
				if (_count == _work.length || endIndex - currentIndex == 1)
				{
					encodeBlock();
					_count = 0;
					_work[0] = 0;
					_work[1] = 0;
					_work[2] = 0;
				}
				currentIndex++;
			}
		}
		
		//Кодирует UTF-8 байты строки в Base64 и добавляет 
		//результат во внутренний буфер
		private static function encodeUTFBytes(data:String):void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes(data);
			bytes.position = 0;
			encodeBytes(bytes);
		}
	

		 //Кодирует байты в формат Base64
		private static function encodeBytes(data:ByteArray, 
											offset:uint=0, 
											length:uint=0):void
		{
			if (length == 0)
				length = data.length;
	
			var oldPosition:uint = data.position;
			data.position = offset;
			var currentIndex:uint = offset;
	
			var endIndex:uint = offset + length;
			if (endIndex > data.length)
				endIndex = data.length;
	
			while (currentIndex < endIndex)
			{
				_work[_count] = data[currentIndex];
				_count++;
	
				if (_count == _work.length || endIndex - currentIndex == 1)
				{
					encodeBlock();
					_count = 0;
					_work[0] = 0;
					_work[1] = 0;
					_work[2] = 0;
				}
				currentIndex++;
			}
	
			data.position = oldPosition;
		}
		
		private static function flushEncoder():String
		{
			if (_count > 0)
				encodeBlock();
	
			var result:String = drainEncoder();
			resetEncoder();
			return result;
		}
	
		//Очистка всех буфферов кодера и приведение его переменных 
		//в начальное состояние
		private static function resetEncoder():void
		{
			_buffers = [];
			_buffers.push([]);
			_count = 0;
			_line = 0;
			_work[0] = 0;
			_work[1] = 0;
			_work[2] = 0;
		}
	
		//Возвращает текущий закодирванный буфер как строку Base64
		private static function toString():String
		{
			return flushEncoder();
		}
	
		private static function encodeBlock():void
		{
			var currentBuffer:Array = _buffers[_buffers.length - 1] as Array;
			if (currentBuffer.length >= MAX_BUFFER_SIZE)
			{
				currentBuffer = [];
				_buffers.push(currentBuffer);
			}
	
			currentBuffer.push(ALPHABET_CHAR_CODES[(_work[0] & 0xFF) >> 2]);
			currentBuffer.push(ALPHABET_CHAR_CODES[((_work[0] & 0x03) << 4) | 
												   ((_work[1] & 0xF0) >> 4)]);
	
			if (_count > 1)
				currentBuffer.push(ALPHABET_CHAR_CODES[((_work[1] & 0x0F) << 2) | 
													   ((_work[2] & 0xC0) >> 6) ]);
			else
				currentBuffer.push(ESCAPE_CHAR_CODE);
	
			if (_count > 2)
				currentBuffer.push(ALPHABET_CHAR_CODES[_work[2] & 0x3F]);
			else
				currentBuffer.push(ESCAPE_CHAR_CODE);
	
			if (insertNewLines)
			{
				if ((_line += 4) == 76)
				{
					currentBuffer.push(newLine);
					_line = 0;
				}
			}
		}
    }
 
}