package com.utils
{
	public class NumberUtils
	{		
		   //Возвращает случайный знак -1 или 1
			public static function randSign() : int
			{
				return ( Math.random() > 0.5 ) ? -1: 1;
			}
			
			//Возвращает случайной число в диапазоне от 0 до n
			public static function random( n : Number ) : Number
			{
				return n * Math.random();
			}
			
			//Округляет число до указанной точности
			public static function roundTo( value : Number, to : uint = 0 ) : Number
			{
				if ( to != 0 )
				{
					var mult : uint = 10;
					for ( var i : int = 0; i < to - 1; i ++ ) mult *= 10;
					
					return Math.round( value * mult ) / mult;
				}
				else return Math.floor( value );
			}
			
			//Определяет являяется ли число целым
			public static function isInteger( value : Number ) : Boolean
			{
				return ( value - Math.floor( value ) ) == 0; 
			}
			
			//Возаращает количество цифер после запятой
			public static function countDigitsAfterDecimalPoint( value : Number ) : uint
			{
				var result : int = 0;
				
				for ( var i : int = 0; i < 10; i ++ )
					if ( ( value - roundTo( value, i ) ) == 0 )
					{
						result = i;
						break;
					}
				
				return result; 
			}
			
			public static function valueToPercent( value : Number, total : Number ) : Number
			{
				return Math.round( ( value / total ) * 100 );
			}
	}
}