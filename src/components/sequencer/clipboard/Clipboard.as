/**
 * Singletone класс для хранения данных в буфере обмена 
 */
package components.sequencer.clipboard
{
	public class Clipboard 
	{
		/**
		 * Перечисление типов данных, которые могут находиться в буфере обмена 
		 */
		
		/**
		 * Ничего 
		 */		
		public static const NONE : int = 0;
		
		/**
		 * Список семплов 
		 */		
		public static const SAMPLES : int = 1;
		
		private static var __instance : ClipboardImplementation;
		
		public static function get impl() : ClipboardImplementation
		{
			if( ! __instance )
			{
				
				__instance = new ClipboardImplementation();
				
			}
			
			return __instance;
		}
		
		//Конструктор
		public function Clipboard()
		{
			throw new Error( "You can't create this class using constructor. For access use impl static property.");
		}
	}
}