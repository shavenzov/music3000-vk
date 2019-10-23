package classes.events
{
	import classes.PaletteSample;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	
	public class PaletteErrorEvent extends ErrorEvent
	{
		public static const ERROR : String = 'paletteError';
		
		public var sample : PaletteSample;
		
		public function PaletteErrorEvent(type:String, sample : PaletteSample, text:String="", id:int=0)
		{
			super(type, false, false, text, id);
			this.sample = sample;
		}
		
		override public function clone():Event
		{
			return new PaletteErrorEvent( type, sample, text, errorID );
		}
	}
}