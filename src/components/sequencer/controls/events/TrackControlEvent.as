package components.sequencer.controls.events
{
	import flash.events.Event;
	
	public class TrackControlEvent extends Event
	{
		public static const SOLO_CHANGED   : String = 'SOLO_CHANGED';
		public static const MONO_CHANGED   : String = 'MONO_CHANGED';
		
		public static const START_VOLUME_CHANGING : String = 'START_VOLUME_CHANGING';
		public static const VOLUME_CHANGING       : String = 'VOLUME_CHANGING';
		public static const VOLUME_CHANGED : String = 'VOLUME_CHANGED';
		
		public static const START_PAN_CHANGING : String = 'START_PAN_CHANGING';
		public static const PAN_CHANGING   : String = 'PAN_CHANGING';
		public static const PAN_CHANGED    : String = 'PAN_CHANGED';
		
		public static const START_NAME_CHANGING : String = 'START_NAME_CHANGING';
		public static const NAME_CHANGED : String = 'NAME_CHANGED'; 
		
		public var number : uint;
		public var name   : String;
		public var mono   : Boolean;
		public var solo   : Boolean;
		public var volume : Number;
		public var pan    : Number;
		
		
		public function TrackControlEvent( type : String, number : uint, name : String, mono : Boolean, solo : Boolean, volume : Number, pan : Number )
		{
			super( type );
			this.name   = name;
			this.number = number;
			this.mono   = mono;
			this.solo   = solo;
			this.volume = volume;
			this.pan    = pan;
		}
	}
}