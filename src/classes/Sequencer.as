/**
 * Синглтон реализующий SequencerImplementation 
 */
package classes
{
	public class Sequencer
	{
		private static var __instance : SequencerImplementation;
		
		public static function get impl() : SequencerImplementation
		{
			if( ! __instance )
			{
				
				__instance = new SequencerImplementation();
				
			}
			
			return __instance;
		}
		
		//Конструктор
		public function Sequencer()
		{
		  throw new Error( "You can't create this class using constructor. For access use impl static property.");
		}
	}
}