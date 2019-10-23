package components.library
{
	import components.controls.Indicator;
	
	import flash.display.GraphicsPathCommand;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	
	import mx.core.UIComponent;
	import mx.states.State;
	
	public class PlayButton extends UIComponent
	{
		private var indicator : Indicator;
		
		public function PlayButton()
		{
			super();
			
			states = [ new State( { name : 'loading' } ), new State( { name : 'play' } ), new State( { name : 'stop' } ) ];
			currentState = 'play';
			
			addEventListener( MouseEvent.ROLL_OVER, onRollOver );
			addEventListener( MouseEvent.ROLL_OUT, onRollOut );
		}
	
		private function onRollOver( e : MouseEvent ) : void
		{
			filters = [ new GlowFilter( 0xffffff, 0.5 ) ];
		}
		
		private function onRollOut( e : MouseEvent ) : void
		{
			filters = null;
		}
		
		override public function set currentState(value:String):void
		{
			super.currentState = value;
			invalidateDisplayList();
		}
		
		private function drawPlayButton() : void
		{
			var c : Vector.<int> = Vector.<int>( [ GraphicsPathCommand.MOVE_TO, GraphicsPathCommand.LINE_TO, GraphicsPathCommand.LINE_TO,
				GraphicsPathCommand.LINE_TO ] );
			
			var path : Vector.<Number> = Vector.<Number>( [ 0.0, 0.0,
				8.0, 5.0,
				0.0, 10.0,
				0.0, 0.0 ] );
			graphics.beginFill( 0xffffff );
			graphics.drawPath( c, path );
			graphics.endFill();
		}
		
		private function drawStopButton() : void
		{
			graphics.beginFill( 0xffffff );
			graphics.drawRect( 0.0, 0.0, 10.0, 10.0 );
			graphics.endFill();
		}
		
		private function drawPauseButton() : void
		{
			graphics.beginFill( 0xffffff );
			graphics.drawRect( 0.0, 0.0, 4.0, 10.0 );
			graphics.drawRect( 6.0, 0.0, 4.0, 10.0 );
			graphics.endFill();
		}
		
		private function drawLoading() : void
		{
			if ( ! indicator )
			{
				indicator = new Indicator();
				indicator.width = 16;
				indicator.height = 16;
				indicator.x = 5;
				indicator.y = 4;
				addChild( indicator );
			}
		}
		
		private function clearLoading() : void
		{
			if ( indicator )
			{
				removeChild( indicator );
				indicator = null;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();
			graphics.beginFill( 0x000000, 0.0 );
			graphics.drawRect( -3, -3, 16, 16 );
			graphics.endFill();
			
			if ( currentState == 'loading' )
			{
				drawLoading();
			}
			else
			{
				clearLoading();
				
				if ( currentState == 'play' )
				{
					drawPlayButton();
				}
				else
				{
					drawPauseButton();
				}
			}
		}
		
		override protected function measure() : void
		{
			measuredWidth = 10;
			measuredHeight = 10;
		}
	}
}