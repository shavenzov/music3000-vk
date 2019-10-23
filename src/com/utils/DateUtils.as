package com.utils
{
	public class DateUtils
	{
		private static const months  : Array = [ 'Янв', 'Фев', 'Мар', 'Апр', 'Мая', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек' ];
		private static const months1 : Array = [ 'Января', 'Февраля', 'Марта', 'Апреля', 'Мая', 'Июня', 'Июля', 'Августа', 'Сентября', 'Октября', 'Ноября', 'Декабря' ];
		
		public static function format( date : Date, shortMonths : Boolean = true ) : String
		{
			var str : String = date.date + ' ' + ( shortMonths ? months[ date.month ] : months1[ date.month ] ) + ' ' + date.fullYear + ' ';
			
			var h : String = date.hours.toString();
			var m : String = date.minutes.toString();
			var s : String = date.seconds.toString();
			
			if ( h.length == 1 ) h = '0' + h;
			if ( m.length == 1 ) m = '0' + m;
			
			return  str + h + ":" + m; 
		}
	}
}