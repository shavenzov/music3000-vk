package com.utils
{
	public class ConjugationUtils
	{
		public static function format( value : int, str1 : String, str234 : String, otherstr : String ) : String
		{
			if ( ( value > 10 ) && ( value < 15 ) )//10,11,12,13,14,15  и т.д. до 20-ти
			{
				value = 0;
			}
			else if ( value > 10 )
			{
				var num : String = value.toString();
				value = parseInt( num.charAt( num.length - 1 ) );
			}
			
			if ( value == 1 ) return str1;
			if ( ( value > 1 ) && ( value < 5 ) ) return str234;
			
			return otherstr;
		}
		
		public static function formatVKVoices( numVoices : int ) : String
		{
			return format( numVoices, 'голос', 'голоса', 'голосов' );
		}
		
		public static function formatCoins( numCoins : int ) : String
		{
			return format( numCoins, 'монета', 'монеты', 'монет' );
		}
		
		public static function formatCoins2( numCoins : int ) : String
		{
			return format( numCoins, 'монету', 'монеты', 'монет' );
		}
		
		public static function formatDays( numDays : int ) : String
		{
			return format( numDays, 'день', 'дня', 'дней' );
		}
	}
}