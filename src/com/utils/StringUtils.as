package com.utils
{
	public class StringUtils
	{
		public static function firstSymbolToUpperCase( str : String ) : String
		{
			return str.charAt( 0 ).toLocaleUpperCase() + str.slice( 1 );
		}
	}
}