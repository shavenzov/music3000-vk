package components.sequencer.timeline
{
	
	import flash.display.GraphicsPathCommand;

	public class RightLoopBorder extends Marker
	{
		private var _initialized : Boolean;
		
		public function RightLoopBorder()
		{
			super();
			
			_stickToGrid = false;
			_snapToGrid = true;
			_snapToGridThenXChange = true;
			
			_cursorWidth  = 10.0;
			_cursorHeight = Settings.RULLER_HEIGHT;
			_offset       = 0.0;
		}
		
		override protected function draw():void
		{
			if ( ! _initialized )
			{
				
				graphics.beginFill( 0xffffff, 0.1 );
				
				graphics.drawPath( 
					Vector.<int>( [ GraphicsPathCommand.MOVE_TO,
						GraphicsPathCommand.CURVE_TO,
						GraphicsPathCommand.CURVE_TO,
					    GraphicsPathCommand.LINE_TO ] ),
					Vector.<Number>( [ 0.0, 0.0,
						               _cursorWidth, 0,
									   _cursorWidth, _cursorHeight / 2,
									   _cursorWidth, _cursorHeight,
									   0, _cursorHeight,
									   0, 0
					                 ])  
				);
				
				graphics.endFill();
				
				_initialized = true;
			}   
		}
	}
}