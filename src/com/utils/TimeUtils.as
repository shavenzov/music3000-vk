package com.utils 
{
	import com.audioengine.core.TimeConversion;

	public class TimeUtils
	{
		public static const MILLISECOND : Number = 1;
		public static const SECOND      : Number = MILLISECOND * 1000;
		public static const MINUTE      : Number = SECOND * 60;
		public static const HOUR        : Number = MINUTE * 60;
		public static const DAY         : Number = HOUR * 24;
		public static const WEEK        : Number = DAY * 7;
		
		/**
		 * Форматирует значение добавляя нули если число меньше 10 
		 * @param value - значение для форматирования
		 * @return строка в отформатированном виде
		 * 
		 */		
		public static function formatValue( value : String, digits : int = 2 ) : String
		{
			while ( value.length < digits )
			{
				value = '0' + value;
			}
			
			return value;
		}
		
		public static function addZeroAfterPoint( value : String ) : String
		{
			if ( value.lastIndexOf( '.' ) == -1 )
			{
				return value + '.0'
			}
			
			return value;
		}
		
		public static function formatbarsToMusicalTime( _bars : Number, delimiter : String = ":" ) : String
		{
			var bars : Number = Math.floor( _bars );
			var bits : Number = Math.floor( ( _bars - bars ) / TimeConversion.BIT_DURATION );
			
			bars ++;
			
			return formatValue( bars.toString(), 3 ) + delimiter + formatValue( bits.toString() );
		}
		
		public static function formatMiliseconds2( _time : Number, html : Boolean = true, delimiter : String = ":" ) : String
		{
			var m  : Number = Math.floor(  _time / MINUTE );
			var s  : Number = Math.floor( ( _time - m * MINUTE ) / SECOND );
			var ms : Number = Math.floor( _time - m * MINUTE - s * SECOND );
			
			var result : String = '';
			
			if ( html )
			{
				result += '<u>';
			}
			
			result += formatValue( m.toString() ) + delimiter + formatValue( s.toString() );
			
			if ( html )
			{
				result += '</u>';
			}
			/*
			if ( html )
			{
				result += '<font color="#808080">';
			}
			*/
			
			if ( ms != 0.0 )
			{
				result += delimiter + formatValue( ms.toString(), 3 );
			}
			
			
			/*
			if ( html )
			{
				result += '</font>';
			}
			*/
			return result; 
		}
		
		public static function formatMiliseconds3( _time : Number, delimiter : String = ":" ) : String
		{
			var m  : Number = Math.floor(  _time / MINUTE );
			var s  : Number = Math.floor( ( _time - m * MINUTE ) / SECOND );
			var ms : Number = Math.floor( _time - m * MINUTE - s * SECOND );
			
			return formatValue( m.toString() ) + delimiter + formatValue( s.toString() );
		} 
		
		public static function formatMiliseconds( _time : Number ) : String
		{
			var m  : Number = Math.floor(  _time / MINUTE );
			var s  : Number = Math.floor( ( _time - m * MINUTE ) / SECOND );
			var ms : Number = Math.floor( _time - ( s * SECOND + m * MINUTE ) );
			
			if ( _time < SECOND )
			{
				return formatValue( Math.round( _time ).toString(), 3 ) + ' мс';
			}
			
			if ( _time < MINUTE )
			{
				return addZeroAfterPoint( ( Math.round( ( _time / SECOND  ) * 10.0 ) / 10.0 ).toString() ) + ' с';
			}
			
			return addZeroAfterPoint( ( Math.round( ( _time / MINUTE ) * 10.0 ) / 10.0 ).toString() ) + ' м';
		}	
		
		/**
		 * Форматирует время в секундах в формате mm:ss 
		 * @param _time - время в секундах
		 * @return 
		 * 
		 */		
		public static function formatSeconds( _time : Number ) : String
		{
			return formatMiliseconds( _time * SECOND );
		}
		
		public static function formatSeconds2( _time : Number, html : Boolean = true ) : String
		{
			return formatMiliseconds2( _time * SECOND, html );
		}
		
		public static function formatSeconds3( _time : Number ) : String
		{
			return formatMiliseconds3( _time * SECOND );
		}
		
		/**
		 * Преобразует милисекунды в секунды 
		 * @param _ms
		 * @return 
		 * 
		 */		
		public static function milisecondsToSeconds( _ms : Number ) : Number
		{
			return _ms / SECOND;
		}	
	}
}