package classes.api
{
	public class MainAPI
	{
		private static var __instance : MainAPIImplementation;
		
		public static function get impl() : MainAPIImplementation
		{
			if( ! __instance )
			{
				
				__instance = new MainAPIImplementation();
				
			}
			
			return __instance;
		}
		
		//Конструктор
		public function MainAPI()
		{
			throw new Error( "You can't create this class using constructor. For access use impl static property.");
		}
	}
}