package classes.events
{
	import flash.events.Event;
	
	public class ChangeBPMEvent extends Event
	{
		public static const BPM_CHANGED : String = 'BPM_CHANGED';
		
		public var newBPM : Number;
		public var oldBPM : Number;
		
		public function ChangeBPMEvent(type:String, newBPM : Number, oldBPM : Number )
		{
			super(type);
			this.newBPM = newBPM;
			this.oldBPM = oldBPM;
		}
		
		override public function clone():Event
		{
		  return new ChangeBPMEvent( type, newBPM, oldBPM );	
		}
	}
}