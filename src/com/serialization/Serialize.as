/**
* ...
* @author Denis Shavenzov
* @version 0.1
* 
* Вспомогательная библиотека
*/
package com.serialization
{
	public class Serialize
	{
	   //Конвертирует строку в булево значение
       public static function toBoolean( str : String ) : Boolean
        {
        	var result : Boolean = false;
            
            str = str.toLowerCase();
            
            if ( ( str == "true" ) || ( str == "1" ) ) result = true;
        	
        	return result;
        }
	   
	   public static function toFloat( str : String ) : Number
	   {
		   var result : Number = parseFloat( str );
		   
		   if ( isNaN( result ) )
			throw new Error( 'Parameter no number.' );
		   
		   return result;
	   }
	   
	   public static function toInt( str : String ) : int
	   {
		   var result : Number = parseInt( str );
		   
		   if ( isNaN( result ) )
			   throw new Error( 'Parameter no number.' );
		   
		   return int( result );
	   }
	   
	   //Парсит шестнадцетиричное значение цвета
	   public static function toColor( hex:String ) : uint
	   {  
		  if ( hex.charAt( 0 ) == '#' )
		  {
			  hex = hex.substring( 1 );
		  }	  
		  
		  return uint( parseInt( '0x' + hex, 16 ) );   
	   }
	   
	   public static function timeStampToDate( time : String ) : Date
	   {
		   return new Date( int( time ) * 1000 );
	   }


	}
}