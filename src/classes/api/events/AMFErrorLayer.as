package classes.api.events
{
	public class AMFErrorLayer
	{
		/**
		 * Ошибка произошла на уровне протокола AMF 
		 */		
		public static const AMF     : uint = 10;
		/**
		 * Ошибка произошла на уровне команды (Например, ошибка выполнения на сервере) 
		 */		
		public static const COMMAND : uint = 20;
	}
}