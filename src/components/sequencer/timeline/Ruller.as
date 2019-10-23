package components.sequencer.timeline
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.TimeConversion;
	import com.utils.TimeUtils;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import mx.core.FTETextField;
	
	import components.ScrollableBase;

	public class Ruller extends ScrollableBase implements IScale
	{
		include 'incs/gridutils.as'
		
		/**
		 *Масштаб Количество секунд в пикселе
		 *Это значение используется для определения длины трека по умолчанию на основании _duration 
		 */
		private var _scale : Number;
		
		/**
		 *Длина объекта в секундах 
		 * 
		 */
		private var _duration : Number;
		
		/**
		 * Как отображать значения на рулетке
		 * MeasureType.MEASURES - в тактах
		 * MeasureType.SECONDS  - в секундах  
		 */		
		private var _viewType : int = MeasureType.SECONDS;
		
		/**
		 * Как отображать сетку
		 * MeasureType.MEASURES - в тактах
		 * MeasureType.SECONDS  - в секундах 
		 */		
		private var _measureType : int = MeasureType.MEASURES;
		
		/**
		 * Скорость воспроизведения ( ударов в минуту ) 
		 */		
		private var _bpm : Number;
		
		/**
		 * Рисовать ли дополнительные засечки 
		 */		
		private var _subDivisions : Boolean = true;
		
		/**
		 * Шаг основных засечек в секундах в масштабе 1:1 ( при measureType = MeasureType.SECONDS ) 
		 */		
		public var _division : Number = AudioData.RATE;
		
		/**
		 * Минимальное расстояние между засечками 
		 */		
		public var _divisionMinStep : Number = 40;
		
		/**
		 * Цвет засечек 
		 */		
		private var _divisionColor : uint = 0xD1AE0F;
		
		/**
		 * Толщина засечек 
		 */		
		public var _divisionWeight : Number = 0.0;
		
		/**
		 * Прозрачность засечек 
		 */		
		private var _divisionAlpha : Number = 1;
		
		/**
		 * Высота засечки 
		 */		
		private var _divisionHeight : Number = 6;
		
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
		private var _subDivisionColor : uint = 0xD1AE0F;
		
		/**
		 * Толщина дополнительных засечек 
		 */		
		private var _subDivisionWeight : Number = 0.1;
		
		/**
		 * Прозрачность дополнительных засечек 
		 */		
		private var _subDivisionAlpha : Number = 1;
		
		/**
		 * Высота дополнительных засечек 
		 */		
		private var _subDivisionHeight : Number = 4;
		
		
		
		/**
		 * Цвет меток 
		 */		
		private var _color : uint = 0xD1AE0F;
		
		/**
		 * Имя шрифта меток 
		 */		
		private var _font : String = 'Calibri';
		
		/**
		 * Размер шрифта меток 
		 */		
		private var _size : int = 12;
		
		/**
		 * Жирный текст меток? 
		 */		
		private var _bold : Boolean = true;
		
		/**
		 * Курсивный текст меток 
		 */		
		private var _italic : Boolean;
		
		/**
		 * Подчеркнутый текст меток 
		 */		
		private var _underline : Boolean;
		
		/**
		 * Данные для отрисовки 
		 */		
		//private var _data     : Vector.<Number> = new Vector.<Number>();
		
		/**
		 * Команды для отрисовки
		 */		
		//private var _commands : Vector.<int>    = new Vector.<int>();
		
		/**
		 * Index for drawing commands 
		 */
		//private var _ci : int;
		
		/**
		 * Index for data commands 
		 */
		//private var _di : int;
		
		/**
		 * Прозрачный задний фон для точного попадания мышью 
		 */		
		private const alphaBG : Shape = new Shape();
		
		/**
		 * Контейнер для размещения меток 
		 * 
		 */
		private const labelsContainer : Sprite = new Sprite();
			
		public function Ruller()
		{
			super();
			
			alphaBG.graphics.beginFill( 0xffffff, 0.0 );
			alphaBG.graphics.drawRect( 0, 0, 10, 10 );
			alphaBG.graphics.endFill();
			
			addChild( labelsContainer );
			addChild( alphaBG );
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
				_needUpdate = true;
			}	
		}
		
		public function get viewType() : int
		{
			return _viewType;
		}
		
		public function set viewType( value : int ) : void
		{
			if ( _viewType != value )
			{
				_viewType = value;
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
				_needUpdate = true;	
			}
		}
		
		public function get scale():Number
		{
			return _scale;
		}
		
		public function set scale(value:Number):void
		{
			_scale = value;
			_needMeasure = true;
			_needUpdate = true;
		}
		
		public function get duration():Number
		{
			return _duration;
		}
		
		public function set duration(value:Number):void
		{
			_duration = value;
			_needMeasure = true;
			_needUpdate = true;
		}
		
		/**
		 * Создает count, меток для отображения 
		 * @param count
		 * 
		 */		
		private function populateLabels( count : int ) : void
		{
			if ( labelsContainer.numChildren > 0 )
			{
				if ( labelsContainer.numChildren > count )
				{
					removeLabels( labelsContainer.numChildren - count );
				}
				else
				{
					addLabels( count - labelsContainer.numChildren );
				}	
			}
			else
			{
				addLabels( count );
			}	
		}
		
		/**
		 * Добавляет указанное количество меток в список 
		 * @param count
		 * 
		 */		
		private function addLabels( count : int ) : void
		{
			if ( count > 0 )
			{
				for ( var i : int = 0; i < count; i ++ ) 
				{
					var _label : FTETextField = new FTETextField();
					_label.autoSize = TextFieldAutoSize.LEFT;    
					_label.embedFonts = true;
					_label.defaultTextFormat = new TextFormat( _font, _size, _color, _bold, _italic, _underline ); 
					_label.mouseEnabled = false;
					//_label.blendMode = BlendMode.OVERLAY;
					
					labelsContainer.addChild( _label );
				}	
			}	
		}
		
		/**
		 * Удаляет указанное количество меток из списка 
		 * @param count
		 * 
		 */
		private function removeLabels( count : int ) : void
		{
			if ( ( count > 0 ) && ( labelsContainer.numChildren >= count ) )
			{
				for ( var i : int = 0; i < count; i ++ )
				{
					labelsContainer.removeChildAt( 0 );	
				}	
			}	
		}	
		
		override protected function measure():void
		{
			contentHeight = Settings.RULLER_HEIGHT;
			contentWidth  = _duration / _scale;
		}
		
		private function touchLabel( index : int, x : Number, barNumber : Number = -1 ) : void
		{
			var _label : FTETextField = FTETextField( labelsContainer.getChildAt( index ) );
			    
			if ( _measureType == MeasureType.MEASURES )
			{
				if ( _viewType == MeasureType.SECONDS )
				{
					_label.text = ( barNumber == 0 ) ? '0' : TimeUtils.formatMiliseconds3( Math.round( TimeConversion.numSamplesToMiliseconds( ( _hsp + x ) * _scale )  ) );	
				}
				else // MeasureType.MEASURES
				{
					_label.text = ( barNumber + 1 ).toString();
				}	
			}
			else
			{
				_label.text = Math.round( TimeConversion.numSamplesToSeconds( ( _hsp + x ) * _scale ) ).toString();
			}	
		     
			var tW : Number = ( _label.textWidth + 5 ) / 2;	
			
			_label.x = ( ( index == 0 ) && ( _hsp < tW  ) ) ? x : x - tW;
				
			_label.y = 0;
		}		
		
		override protected function update():void
		{
			//_ci = 0;
			//_di = 0;
			var x : Number;
			var i : int = 0;
			var _currentDivision : Number;
			
			//Расчитываем интервал основной сетки в масштабе 1:1
			if ( _measureType == MeasureType.MEASURES )
			{
				_currentDivision   = TimeConversion.barsToNumSamples( 1, _bpm );
			}
			else
			{
				_currentDivision = _division;
			}	
			
			//Определяем шаг основной сетки в пикселях
			var step  : Number = getOptimizedStep( _currentDivision, _divisionMinStep );
			 
			x = - ( _hsp - ( Math.ceil( _hsp / step ) * step ) );
			x = Math.round( x * 100 ) / 100;
			
			var count : Number = Math.ceil( ( _scrollWidth - x ) / step );
			
			//Создаем необходимое количество меток
			populateLabels( count );	
			
			while( i < count )
			{
				/*_commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_data[ _di ++ ]     = x;
				_data[ _di ++ ]     = contentHeight;
				
				_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
				_data[ _di ++ ]     = x;
				_data[ _di ++ ]     = contentHeight - _divisionHeight;*/
				
				//if ( _viewType == MeasureType.MEASURES )
				//{
					touchLabel( i, x, Math.round( ( ( _hsp + x ) * _scale ) / _currentDivision ) );
				/*}	
				else
				{
					touchLabel( i, x );		
				}*/
				
				x += step;
				i ++;
			}
			
			alphaBG.width = scrollWidth;
			alphaBG.height = scrollHeight;
			
			/*
			if ( _ci < _commands.length )
			{
				_commands.splice(_ci, _commands.length - _ci);
				_data.splice(_di, _data.length - _di);
			}	
			*/
			//Отрисовываем
			/*
			graphics.clear();
			
			//Отрисовываем прозрачный задний фон
			graphics.beginFill( 0xFFFFFF, 0.0 );
			graphics.drawRect( 0, 0, scrollWidth, scrollHeight );
			graphics.endFill();
			
			graphics.lineStyle( _divisionWeight, _divisionColor, _divisionAlpha );
			graphics.drawPath( _commands, _data );*/
			
			//if ( ! _subDivisions || _measureType == MeasureType.MEASURES ) return;
			
			//Расчитываем интервал дополнительной сетки в масштабе 1:1
			/*if ( _measureType == MeasureType.MEASURES )
			{
				_currentDivision   = TimeConversion.bitsToNumSamples( 1, _bpm );
			}
			else
			{
				_currentDivision = _subDivision;
			}
			
			//Рисуем дополнительные засечки
			//Определяем шаг дополнительной сетки в пикселях
			step = getOptimizedStep( _subDivision, _subDivisionMinStep );
			
			x = - ( _hsp - ( Math.floor( _hsp / step ) * step ) );
			
			_ci = 0;
			_di = 0;
			
			while( x < _scrollWidth )
			{
				_commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_data[ _di ++ ]     = x;
				_data[ _di ++ ]     = contentHeight;
				
				_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
				_data[ _di ++ ]     = x;
				_data[ _di ++ ]     = contentHeight - _subDivisionHeight;
				
				x += step;
			}
			
			if ( _ci < _commands.length )
			{
				_commands.splice(_ci, _commands.length - _ci);
				_data.splice(_di, _data.length - _di);
			}	
			
			graphics.lineStyle( _subDivisionWeight, _subDivisionColor, _subDivisionAlpha );
			graphics.drawPath( _commands, _data );*/
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