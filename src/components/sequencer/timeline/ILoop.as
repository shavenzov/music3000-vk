package components.sequencer.timeline
{
	public interface ILoop
	{
		function get loopDuration() : Number;
		function set loopDuration( value : Number ) : void;
		
		function get timeLoopDuration() : Number;
		function set timeLoopDuration( value : Number ) : void
		
		function get offset() : Number;
		function set offset( value : Number ) : void;
		
		function get timeOffset() : Number;
		function set timeOffset( value : Number ) : void;	
	}
}