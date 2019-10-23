/**
 * Задний фон Шкалы времени 
 */
package components.sequencer.timeline
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.TimeConversion;
	
	import components.ScrollableBase;
	import components.sequencer.ColorPalette;
	import components.sequencer.timeline.events.MarkerChangeEvent;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.GraphicsPathCommand;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class VGrid extends ScrollableBase implements IScale
	{
		include 'incs/gridutils.as'
		
		/**
		 * Данные для отрисовки 
		 */		
		private var _data     : Vector.<Number> = new Vector.<Number>();
		
		/**
		 * Команды для отрисовки
		 */		
		private var _commands : Vector.<int>    = new Vector.<int>();
		
		/**
		 * Index for drawing commands 
		 */
		private var _ci : int;
		
		/**
		 * Index for data commands 
		 */
		private var _di : int;
		
		/**
		 * Как отображать сетку
		 * MeasureType.MEASURES - в тактах
		 * MeasureType.SECONDS  - в секундах 
		 */		
		private var _measureType : int = MeasureType.MEASURES;
		
		/**
		 * Рисовать ли дополнительные засечки 
		 */		
		private var _subDivisions : Boolean = true;
		
		/**
		 * Шаг дополнительных засечек в секундах в масштабе 1:1 ( при measureType = MeasureType.SECONDS )
		 */		
		private var _subDivision : Number = 0.1 * AudioData.RATE;
		
		/**
		 * Минимальное расстояние между дополнительными засечками 
		 */		
		private var _subDivisionMinStep : Number = 4;
		
		/**
		 * Цвет дополнительных засечек 
		 */		
		private var _subDivisionColor : uint = 0xFFFFFF;
		
		/**
		 * Толщина дополнительных засечек 
		 */		
		private var _subDivisionWeight : Number = 0.0;
		
		/**
		 * Прозрачность дополнительных засечек 
		 */		
		private var _subDivisionAlpha : Number = 0.1;
		
		/**
		 * Скорость воспроизведения ( ударов в минуту ) 
		 */		
		private var _bpm : Number = 140.0;
		
		/**
		 * Текущий шаг засечек в фреймах в масштабе 1:1 
		 */		
		protected var _currentDivision : Number = 0;
		
		/**
		 * Текущий шаг дополнительных засечек в масштабе 1:1 
		 */		
		protected var _currentSubDivision : Number = 0;
		
		/**
		 * Шаг засечек в фреймах в масштабе 1:1 ( для режима отрисовки сетки MeasureType.SECONDS )
		 */		
		public var _division : Number = AudioData.RATE;
		
		/**
		 * Минимальное расстояние между засечками 
		 */		
		public var _divisionMinStep : Number = 40;
		
		/**
		 * Цвет засечек 
		 */		
		public var _divisionColor : uint = 0xFFFFFF;
		
		/**
		 * Толщина засечек 
		 */		
		public var _divisionWeight : Number = 0.0;
		
		/**
		 * Прозрачность засечек 
		 */		
		public var _divisionAlpha : Number = 0.5;
		
		/**
		 *Масштаб Количество секунд в пикселе
		 *Это значение используется для определения длины трека по умолчанию на основании _duration 
		 */
		protected var _scale        : Number = 100.0;
		
		/**
		 *Длина объекта в секундах 
		 * 
		 */
		protected var _duration        : Number = 3 * AudioData.RATE;
		
		/**
		 * Необходим перерасчитать параметры перед отрисовкой 
		 */		
		private var _needRecalc : Boolean;
		
		/**
		 * Оптимизированная длина объекта в секундах для нилучшего отображения 
		 */		
		private var _optimizedDuration : Number;
		
		/**
		 * Реальная длина компонента 
		 */		
		private var _trackWidth : Number;
		
		public function VGrid()
		{
			super();
		}
		
		public function get scale():Number
		{
			return _scale;
		}
		
		public function set scale(value:Number):void
		{
			if ( _scale != value )
			{  
				_scale = value;
				
				_needRecalc = true;
				_needMeasure = true;
				_needUpdate  = true;
			}
		}
		
		public function get duration():Number
		{
			return _duration;
		}
		
		public function set duration(value:Number):void
		{
			if ( _duration != value )
			{
				_duration = value;
				
				_needRecalc = true;
				_needMeasure = true;
				_needUpdate = true;
			}
		}
		
		/**
		 * Оптимизированное значение длительности 
		 * 
		 */		
		public function get optimizedDuration() : Number
		{
			calculateOptimizedDuration();
			return _optimizedDuration;
		}
		
		private function calculateOptimizedDuration() : void
		{
			if ( _needRecalc )
			{
				_optimizedDuration = getOptimizedDuration( _scale, _duration ); 
				_needRecalc = false;
			}
		}
		
		/**
		 * Возвращает длину, которая будет установлена для компонента с указанным scale и duration 
		 * @param scale
		 * @param duration
		 * @return 
		 * 
		 */		
		public function getOptimizedDuration( scale : Number, duration : Number ) : Number
		{
			calculateCurrentDivision();
			return duration + getOptimizedStep( _currentDivision, _divisionMinStep ) * scale;
		}
		
		public function getOptimizedContentWidth( scale : Number, duration : Number ) : Number
		{
			return getOptimizedDuration( scale, duration ) / scale;
		}	
		
		override protected function measure() : void	
		{
			calculateOptimizedDuration();
			
			contentWidth  = _optimizedDuration / _scale;
			_trackWidth   = _duration / _scale;
		}
		
		private function drawGrid( w : Number, h : Number ) : void
		{
			_ci = 0;
			_di = 0;
	
			var x   : Number;
			
			//Определяем шаг основной сетки в пикселях
			var step  : Number = getOptimizedStep( _currentDivision, _divisionMinStep );
			
			x = step - ( _hsp - ( Math.floor( _hsp / step ) * step ) );
			
			//!!!!!
			_commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
			_data[ _di ++ ]     = 0.0;
			_data[ _di ++ ]     = 0.0; 
			
			_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
			_data[ _di ++ ]     = 0.0;
			_data[ _di ++ ]     = h;
			
			while( x < scrollWidth )
			{
				_commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_data[ _di ++ ]     = x;
				_data[ _di ++ ]     = 0.0;
				
				_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
				_data[ _di ++ ]     = x;
				_data[ _di ++ ]     = h;
				
				x += step;
			}
			
			if ( _ci < _commands.length )
			{
				_commands.splice(_ci, _commands.length - _ci);
				_data.splice(_di, _data.length - _di);
			}	
			
			//Отрисовываем
			graphics.clear();
			
			//Отрисовываем красный квадратик
			var end : Number = _hsp + scrollWidth;
			
			if ( end > _trackWidth )
			{
				var emptyW : Number = end - _trackWidth;
				
				graphics.beginFill( 0xFF0000, 0.15 );
				graphics.drawRect( scrollWidth  - emptyW, 0, emptyW, h );  
				graphics.endFill();
			}	
			
			graphics.lineStyle( _divisionWeight, _divisionColor, _divisionAlpha );
			graphics.drawPath( _commands, _data );
			
			//Дополнительная сетка
			if ( _subDivisions && _measureType == MeasureType.MEASURES )
			{
				//Рисуем дополнительные засечки
				//Определяем шаг дополнительной сетки в пикселях
				step = getOptimizedStep( _currentSubDivision, _subDivisionMinStep );
				
				_ci = 0;
				_di = 0;
				
				//trace( 'VGrid current division ' + _currentSubDivision );
				
				x = step - ( _hsp - ( Math.floor( _hsp / step ) * step ) );
				
				while( x < scrollWidth )
				{
					_commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
					_data[ _di ++ ]     = x;
					_data[ _di ++ ]     = 0;
					
					_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
					_data[ _di ++ ]     = x;
					_data[ _di ++ ]     = h;
					
					x += step;
				}
				
				if ( _ci < _commands.length )
				{
					_commands.splice(_ci, _commands.length - _ci);
					_data.splice(_di, _data.length - _di);
				}	
				
				//Отрисовываем
				graphics.lineStyle( _subDivisionWeight, _subDivisionColor, _subDivisionAlpha );
				graphics.drawPath( _commands, _data );
			}
		}
		
		private function calculateCurrentDivision() : void
		{
			if ( _measureType == MeasureType.MEASURES )
			{
				_currentDivision    = TimeConversion.barsToNumSamples( 1, _bpm );
				_currentSubDivision = TimeConversion.bitsToNumSamples( 1, _bpm );
				return;
			}
			
			if ( _measureType == MeasureType.SECONDS )
			{
				_currentDivision = _division;
				return;
			}	
		}	
		
		public function get measureType() : int
		{
			return _measureType;
		}
		
		public function set measureType( value : int ) : void
		{
			if ( _measureType != value )
			{
				_measureType = value;
				_needRecalc = true;
				_needUpdate = true;
			}	
		}
		
		public function get bpm() : int
		{
			return _bpm;
		}
		
		public function set bpm( value : int ) : void
		{
			if ( _bpm != value )
			{
				_bpm = value;
				_needRecalc = true;
				_needUpdate = true;	
			}
		}	
		
		override protected function update():void
		{
			calculateOptimizedDuration();	
			
			var len : Number = _vsp + _scrollHeight;
			
			if ( len > contentHeight )
			{
				drawGrid( scrollWidth, scrollHeight - ( len - contentHeight ) );
			}	
			else
			{
				drawGrid( scrollWidth, scrollHeight );
			}
			
			
		}
		
		override public function updateScrollRect():void
		{
			if ( _scrollRectChanged )
			{
				update();
				scrollRect = new Rectangle( 0, 0, _scrollWidth, _scrollHeight );
				_scrollRectChanged = false;
			}
		}	
	}
}