package components.sequencer.controls.events
{
	import flash.events.Event;
	
	public class TrackControlSwapEvent extends Event
	{
		public static const SWAP : String = 'SWAP';
		
		public var index1 : int;
		public var index2 : int;
		
		public function TrackControlSwapEvent( type : String, index1 : int, index2 : int )
		{
			super( type );
			this.index1 = index1;
			this.index2 = index2;
		}
		
		override public function clone():Event
		{	
			return new TrackControlSwapEvent( type, index1, index2 );
		}
	}
}