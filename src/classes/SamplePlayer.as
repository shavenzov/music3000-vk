/**
 * Синглтон реализующий SequencerImplementation 
 */
package classes
{
	public class SamplePlayer
	{
		private static var __instance : SamplePlayerImplementation;
		
		public static function get impl() : SamplePlayerImplementation
		{
			if( ! __instance )
			{
				
				__instance = new SamplePlayerImplementation();
				
			}
			
			return __instance;
		}	
		
		//Конструктор
		public function SamplePlayer()
		{
		  throw new Error( "You can't create this class using constructor. For access use impl static property.");
		}
	}
}