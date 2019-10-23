package components.sequencer.controls.navigatorClasses
{
	import flash.display.GraphicsPathCommand;
	import flash.display.Shape;
	
	public class TracksView extends Shape
	{
		/**
		 * Данные для отрисовки 
		 */		
		private var _data     : Vector.<Number> = new Vector.<Number>();
		
		/**
		 * Команды для отрисовки
		 */		
		private var _commands : Vector.<int>    = new Vector.<int>();
		
		private var _ci : int;
		private var _di : int;
		
		public function TracksView()
		{
			super();
		}
		
		public function draw( w : Number, numTracks : int, trackHeight : Number ) : void
		{
			var i   : int = 0;
			
			_ci = 0;
			_di = 0;
			
			numTracks ++;
			
			while( i < numTracks )
			{
				var y : Number = i * trackHeight;
				
				_commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_data[ _di ++ ]     = 0.0;
				_data[ _di ++ ]     = y;
				
				_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
				_data[ _di ++ ]     = w;
				_data[ _di ++ ]     = y;
				
				i ++;
			}
			
			if ( _ci < _commands.length )
			{
				_commands.splice(_ci, _commands.length - _ci);
				_data.splice(_di, _data.length - _di);
			}
			
			graphics.clear();
			graphics.lineStyle( 0.0, 0xFFFFFF, 0.03 );
			graphics.drawPath( _commands, _data );
			
		}	
	}
}