package classes.soundwave
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IAudioData;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class BaseSoundWaveGraphic extends EventDispatcher implements ISoundWaveGraphic
	{
		/**
		 * Максимальная длина одного фрагмента звуковой волны, по умолчанию 
		 */		
		public static const MAX_WIDTH : int = 6000;
		
		/**
		 * Масив изображений визуализации данных звуковой волны
		 * Каждое изображение имеет максимальную ширину MAX_WIDTH px 
		 */		
		public var graphics : Vector.<BitmapData>;
		
		/**
		 * Ссылка на данные для отрисовки 
		 */		
		protected var _data : IAudioData;
		
		/**
		 * Каким цветом отрисовывать 
		 */		
		protected var _color : uint;
		/**
		 * С какой прозрачностью отрисовывать 
		 */		
		protected var _alpha : Number;
		
		/**
		 * Идентификатор 
		 */		
		protected var _id : String;
		
		/**
		 * Указывает, что данные графика устарели и нуждаются в обновлении. Использовать их в данный момент нельзя. 
		 */		
		private var _needUpdate : Boolean = true;
		
		/**
		 * Указывает, что график перерисовывается при изменении масштаба
		 */		
		private var _scaleChange : Boolean = true;
		
		/**
		 *  Указывает, что график перерисовывается при изменении bpm
		 */		
		private var _bpmChange : Boolean = true;
		
		/**
		 * Определяет сколько объектов используют этот SoundWaveGraphic 
		 */		
		private var _links : int;
		
		protected var _w : Number;
		protected var _h : Number;
		
		/**
		 * Общее количество итераций необходимых для отрисоски волны 
		 */		
		private var _iterations : int;
		
		/**
		 * Текущее значение итерации 
		 */		
		private var _currentIteration : int;
		
		/**
		 * Флаг показывающий, что в данный момент идет процесс отрисовки 
		 */		
		private var _rendering : Boolean;
		
		/**
		 * Указывает, что объект заблокирован потоком 
		 */		
		private var _locked : Boolean;
		
		public function BaseSoundWaveGraphic( data : IAudioData, id : String, scalechange : Boolean, bpmChange : Boolean, color : uint = 0x000000, alpha : Number = 1.0 )
		{
		  super();
		  _data = data;
		  _color = color;
		  _alpha = alpha;
		  _id = id;
		  
		  _scaleChange = scaleChange;
		  _bpmChange   = bpmChange;
		}
		
		public function get locked() : Boolean
		{
			return _locked;
		}
		
		public function set locked( value : Boolean ) : void
		{
			_locked = value;
		}	
		
		public function get needUpdate() : Boolean
		{
			return _needUpdate;
		}
		
		public function set needUpdate( value : Boolean ) : void
		{
			_needUpdate = value;
		}
		
		public function get scaleChange() : Boolean
		{
			return _scaleChange;
		}
		
		public function get bpmChange() : Boolean
		{
			return _bpmChange;
		}
		
		public function attach() : void
		{
			_links ++;
		}
		
		public function dettach() : void
		{
			_links --;
		}	
		
	    public function get links() : int
		{
			return _links;
		}	
		
		public function get id() : String
		{
			return _id;
		}	
		
		public function get data() : IAudioData
		{
			return _data;
		}
		
		public function get w() : int
		{
		  return _w;
		}
		
		public function set w( value : int ) : void
		{
			if ( value != _w )
			{
				_w = value;
				needUpdate = true;
			}	
		}
		
		public function get h() : Number
		{
			return _h;
		}
		
		public function set h( value : Number ) : void
		{
			if ( value != _h )
			{
				_h = value;
				needUpdate = true;	
			}
		}
		
		public function get iterations() : int
		{
			return _iterations;
		}
		
		public function get currentIteration() : int
		{
			return _currentIteration;
		}
		
		public function get rendering() : Boolean
		{
			return _rendering;
		}	
		
		public function copy( srcOffset : int, length : int ) : Vector.<BitmapData>
		{
			var result : Vector.<BitmapData> = new Vector.<BitmapData>();
			
			var stIndex   : int = srcOffset / MAX_WIDTH;
			var endIndex  : int = ( srcOffset + length ) / MAX_WIDTH;
			var indexRange: int = endIndex - stIndex;
			var cLen      : int = 0;
			var cIndex    : int = stIndex;
			var remaining : int = length;
			var offset    : int = srcOffset - stIndex * MAX_WIDTH
			
			var cG        : BitmapData;
			
			while( remaining > 0 )
			{
				cG = graphics[ cIndex ];
				
				if ( ( cIndex == stIndex ) && ( indexRange > 0 ) )
				{
					cLen = cG.width - offset; 
				}
				else
				{
					cLen = Math.min( remaining, MAX_WIDTH );
				}	
				
				var b : BitmapData = new BitmapData( cLen, _h, true, 0xffffff );
				    b.copyPixels( cG, new Rectangle( offset, 0, cLen, _h ), new Point( 0.0, 0.0 ) );
						
				result.push( b );		
				
				offset = 0;
				cIndex ++;
				remaining -= cLen;
			}
			
			return result;
		}	
		
		private var _halfHeight : Number;
		private var step : int;
		private var _renderW : Number;
		
		/**
		 * Инициирует начало отрисовки всей звуковой волны 
		 * 
		 */		
		public function startUpdate() : void
		{
			_rendering = true;
			_iterations = Math.ceil( _w / MAX_WIDTH );
			_currentIteration = 0;
			
			clearGraphics();
			
			_renderW = 0.0;
			_halfHeight = _h / 2;
			step = AudioData.bytesToFrames( _data.data.length ) / _w;
			graphics = new Vector.<BitmapData>( _iterations );
			
			_lastW = _w;
			_lastDataLength = _data.data.length;
		}
		
		private var _lastDataLength : int;
		private var _lastW          : int;
		private var _dataPos        : int;
		
		private function startUpdateChanged() : void
		{
			_rendering = true;
			/*
			Рассматривается только случай увеличения размера данных
			*/
			_iterations = ( Math.ceil( _w / MAX_WIDTH ) - Math.ceil( _lastW / MAX_WIDTH ) ) + 1;
			
			_currentIteration = 0;
				
			_halfHeight = _h / 2;
			
			step = AudioData.bytesToFrames( _data.data.length - _lastDataLength ) /  ( _w - _lastW );
			
			_renderW = _lastW;
			_dataPos = AudioData.bytesToFrames( _lastDataLength );
			_lastDataLength = _data.data.length;
			_lastW          = _w;
		}	
		
		public function endUpdate() : void
		{
			_rendering = false;
			_needUpdate = false;
			dispatchEvent( new Event( Event.CHANGE ) );
		}
		
		/**
		 * Обновляет определенный участок графика звуковой волны
		 * 
		 */		
		public function updateChange() : void
		{
			var cBlock : int = Math.floor( _renderW / MAX_WIDTH );
			var cW : Number = Math.min( _w - _renderW, ( cBlock + 1 ) * MAX_WIDTH - _renderW );
			
			var s : Shape = new Shape();
			
			initDraw( s.graphics, cW, _halfHeight, _dataPos, step );
			
			var b : BitmapData;
			
			if ( cBlock < graphics.length )
			{	
				var g : BitmapData = graphics[ cBlock ];
				
				b = new BitmapData( g.width + cW, h, true, 0xffffff );
				b.draw( g, null, null, null, null, true );
				b.draw( s, new Matrix( 1.0, 0.0, 0.0, 1.0, g.width ), null, null, null, true );
				
				graphics[ cBlock ] = b;
			}
			else
			{
				b = new BitmapData( cW, h, true, 0xffffff );
				b.draw( s, null, null, null, null, true );
				
				graphics.push( b );
			}
			
			_renderW += cW;
			_dataPos += cW * step;
			
			_currentIteration ++;
		}
		
		/**
		 * Обновляет график звуковой волны 
		 * @param w
		 * @param h
		 * 
		 */		
		public function update() : void
		{
		  var cW : Number = Math.min( _w - _renderW, MAX_WIDTH );
		  var s : Shape = new Shape();
		  var from : int = _renderW * step;
		  
		  initDraw( s.graphics, cW, _halfHeight, from, step );
		   
		  var b : BitmapData = new BitmapData( cW, h, true, 0xffffff );
			  b.draw( s, null, null, null, null, true );
			  
			  graphics[ _currentIteration ] = b;
			  _renderW += cW;
			  _currentIteration ++;  
		}
		
		/**
		 * Обновляет график звуковой волны синхронно за один раз 
		 * 
		 */		
		public function updateNow() : void
		{
			startUpdate();
			
			while( _currentIteration < _iterations )
			{
				update();
			}	
			
			endUpdate();
		}
		
		/**
		 * Перерисовывает только те куски графика которые изменились, не перерисовывая остальные 
		 * 
		 */		
		public function updateChangedData() : void
		{	
			if ( ! graphics || ( graphics.length == 0 ) )
			{
				updateNow();
				return;
			}
			
			if ( ( _lastW > _w ) || ( _lastDataLength >= data.data.length ) )
			{
				updateNow();
				return;
			}
			
			startUpdateChanged();
			
			while( _currentIteration < _iterations )
			{
				updateChange(); 	 
			}	
			
			
			endUpdate();
		}
		
		private function initDraw(  g : Graphics, w : Number, halfHeight : Number, dataOffset : int, step : int, maxValue : Number = 2.0 ) : void
		{
			var pos : int = _data.data.position; //Запоминаем позицию
			draw( g, w, halfHeight, dataOffset, step, maxValue );
			_data.data.position = pos;  //Востанавливаем позицию
		}	
		
		/**
		 * Отрисовывает график звуковой волны на указанном Graphics 
		 * @param g
		 * @param w
		 * @param h
		 * @param dataOffset
		 * 
		 */		
		protected function draw( g : Graphics, w : Number, halfHeight : Number, dataOffset : int, step : int, maxValue : Number = 2.0 ) : void
		{
			
		}	
		
		private function clearGraphics() : void
		{  
			//Удаляю предыдущие графики
			if ( graphics )
			{
				var i : int = 0;
				
				while ( i < graphics.length )
				{
					if ( graphics[ i ] )
					{
						graphics[ i ].dispose();
						graphics[ i ] = null;
					}	
					
					i ++;
				}
				
				graphics = null;
			}
		}
		
		public function clear() : void
		{
			clearGraphics();
			
			_rendering = false;
			_locked = false;
			_needUpdate = false;
			_links = 0;
		}	
		
	}
}