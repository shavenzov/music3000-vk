package classes.events
{
	import flash.events.Event;
	
	public class SamplePlayerEvent extends Event
	{
		/**
		 * Событие генерируется каждый раз при вызове метода play
		 */		
		public static const START_PLAYING : String = 'START_PLAYING';
		/**
		 * Событие генерируется каждый раз при вызове метода stop 
		 */		
		public static const STOP_PLAYING : String = 'STOP_PLAYING';
		/**
		 * Событие генерируется каждый раз при вызове метода pause 
		 */		
		public static const PAUSE_PLAYING : String = 'PAUSE_PLAYING';
		
		/**
		 * Событие по таймеру "обновлении позиции курсора воспроизведения" 
		 */		
		public static const POSITION_UPDATED : String = 'POSITION_UPDATED';
		
		public function SamplePlayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}