package components.primitives
{
	import com.utils.NumberUtils;
	
	import flash.display.Graphics;
	import flash.display.GraphicsPathCommand;
	
	import spark.primitives.supportClasses.FilledElement;
	
	public class LineFilledRectangle extends FilledElement
	{
		/**
		 * Интервал расположения прямых 
		 */		
		private var _interval : Number = 10;
		
		/**
		 * Угол в градусах под которым будут рисоваться линии 
		 */		
		private var _angle : Number = 45;
		
		/**
		 * Тангенс угла поворота в радианах
		 */		
		private var _k : Number;
		
		public function LineFilledRectangle()
		{
			super();
		}
		
		/**
		 * Интервал расположения прямых 
		 */
		public function get interval() : Number
		{
			return _interval;
		}
		
		public function set interval( value : Number ) : void
		{
			if ( _interval != value )
			{
				_interval = value;
				invalidateDisplayList();
			}	
		}
		
		/**
		 * Угол в градусах под которым будут рисоваться линии 
		 */	
		public function get angle() : Number
		{
			return _angle;
		}
		
		public function set angle( value : Number ) : void
		{
			if ( _angle != value )
			{
				_angle = value;
				
				_k = Math.tan( _angle / 180 * Math.PI );
				invalidateDisplayList();
			}	
		}	
		
		override protected function draw( g : Graphics ) : void
		{
			var _data     : Vector.<Number> = new Vector.<Number>(); 
			var _commands : Vector.<int>    = new Vector.<int>();    
            
			//Количество засечек
			var count : Number = Math.ceil( width / _interval );     
			
			for ( var i : int = 0; i < count * 2; i ++ )
			{
				var x1 : Number = ( i * _interval ) + _interval;
				_commands.push( GraphicsPathCommand.MOVE_TO, GraphicsPathCommand.LINE_TO );
				_data.push( x1, -5, ( height / _k ) + x1, height ); 
			}
			
			g.drawPath( _commands, _data );
		}	
		
	}
}