package classes.events
{
	import flash.events.Event;
	
	public class CreateTrackEvent extends Event
	{
		public static const CREATE_TRACK : String = 'CREATE_TRACK';
		
		public var createAt  : int;
		public var numTracks : int;
		
		public function CreateTrackEvent( type:String, createAt : int, numTracks : int )
		{
			super( type );
			this.createAt  = createAt;
			this.numTracks = numTracks;
		}
		
		override public function clone() : Event
		{
			return new CreateTrackEvent( type, createAt, numTracks );
		}	
	}
}