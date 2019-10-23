package components.sequencer.timeline
{
	import flash.display.GraphicsPathCommand;

	public class DurationHead extends Marker
	{	
		public function DurationHead()
		{
			super();
			_stickToGrid = false;
			_cursorWidth  = 15;
			_cursorHeight = 18;
			_offset       = _cursorWidth / 2;
		}
		
		override protected function draw():void
		{
			graphics.clear();
			graphics.beginFill( 0xB22222 );
			   
			graphics.drawPath( 
				   Vector.<int>( [ GraphicsPathCommand.MOVE_TO,
					   GraphicsPathCommand.CURVE_TO,
					   GraphicsPathCommand.LINE_TO,
					   GraphicsPathCommand.CURVE_TO ] ),
				   Vector.<Number>( [ 15.0, 0.0,
					   7.875, 18.375, 7.5, 18,
					   0, 0,
					   6.975, 3.675, 15.0, 0
				   ])  
			   ); 
			   
			graphics.endFill();
			   
			   graphics.lineStyle( 2, 0xB22222, 0.75 );
			   graphics.drawPath( 
				   Vector.<int>( [ GraphicsPathCommand.MOVE_TO, GraphicsPathCommand.LINE_TO] ),
				   Vector.<Number>( [ _offset, _cursorHeight, _offset, contentHeight ] )  
			   );   
		}	
	}
}