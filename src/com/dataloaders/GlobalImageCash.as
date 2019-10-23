package com.dataloaders
{

	public class GlobalImageCash
	{
		private static var __instance : ImageCash;
		
		public static function get impl() : ImageCash
		{
			if( ! __instance )
			{
				
				__instance = new ImageCash();
				
			}
			
			return __instance;
		}	
		
		//Конструктор
		public function GlobalImageCash()
		{
			throw new Error( "You can't create this class using constructor. For access use impl static property.");
		}
	}
}