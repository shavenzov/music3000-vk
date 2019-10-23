package components.sequencer.timeline.visual_sample
{
	import classes.Sequencer;
	import classes.soundwave.ISoundWaveGraphic;
	import classes.soundwave.SoundWaveGraphicCache;
	
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IAudioData;
	import com.audioengine.sequencer.AudioLoop;
	
	import components.Base;
	import components.sequencer.ColorPalette;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GraphicsPathCommand;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import mx.core.FTETextField;
	import mx.core.IToolTip;

	public class VisualSample extends BaseVisualSample
	{
		private static const selected_and_hovered_alpha : Number = 0.98;
		private static const selected_alpha             : Number = 0.98;
		private static const unselected_alpha           : Number = 0.4;
		private static const hovered_alpha              : Number = 0.6;
		
		//Длина образца слева
		private var leftLength : Number;
		//Общее кол-во "целых" семплов в лупе
		private var hole : int;
		//Остающаяся длина справа
		private var rightLength : Number;
		private var loopWidth : Number;
		
		private var _cornerRadius : Number = 20;
		
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
		 * Отображение названия семпла
		 */		
		public var label : FTETextField;
		
		private var loaderIndicator : Preloader;
		private var errorButton : ErrorButton;
		
		/**
		 * Определяет выбран ли в данный момент семпл 
		 */		
		protected var _selected : Boolean;
		
		/**
		 * Определяет наведен ли курсор на семпл 
		 */		
		protected var _hovered  : Boolean;
		
		/**
		 * Минимальный размер при котором ещё отображается название 
		 */		
		public static const minWidth      : Number = 30.0;
		public static const textMinHeight : Number = 18.0;
		public static const widthForToolTip : Number = 80.0;
		
		/**
		 * Кеш звуковых волн 
		 */		
		private var waves : SoundWaveGraphicCache;
		/**
		 * Звуковая волна связанная с этим семплом 
		 * 
		 */
		public var wave : ISoundWaveGraphic;
		
		/**
		 * Контейнер в котором располагается отрисованная Волна 
		 */		
		private var _waveContainer : Sprite;
		
		/**
		 * Ссылка на всплывающую подсказку, отображаемый при наведении если объект слишком маленький 
		 */		
		public var toolTip : IToolTip;
		
		/**
		 * Сэмпл находится в состоянии ошибки 
		 */		
		private var _error : Boolean;
		
		/**
		 * Сэмпл находится в состоянии загрузки 
		 */		
		private var _loading : Boolean;
		
		public function VisualSample()
		{
			super();
			
			waves = classes.Sequencer.impl.palette.waves;
			
			cacheAsBitmap = true;
			
			label = new FTETextField();
			label.wordWrap = true;
			label.multiline = true;
			label.embedFonts = true;
			label.mouseEnabled = false;
			label.defaultTextFormat = new TextFormat( 'Calibri', 12, 0xffffff, false );
			//label.alpha = 0.75;
			
			_waveContainer = new Sprite();
			_waveContainer.cacheAsBitmap = true;
			_waveContainer.alpha = 0.65;
			_waveContainer.visible = false;
			
			addChild( _waveContainer );
			addChild( label );
		}
		
		public function get indicator() : Base
		{
			if ( loaderIndicator ) return loaderIndicator;
			if ( errorButton ) return errorButton;
			
			return null;
		}
		
		public function detachFromWave() : void
		{
			if ( wave )
			{
				wave.removeEventListener( Event.CHANGE, onChangedWave );
				waves.detachW( wave.id );
			    wave = null;
			}	
		}	
		
		public function get waveIsAttached() : Boolean
		{
			return wave != null;
		}	
		
		public function attachToWave( constant : Boolean = false, inverted : Boolean = false, update : Boolean = true ) : void
		{
			if ( _loading || _error )
			{
				return;
			}
			
			detachFromWave();
			
			var _wave_id : String;
			var source   : IAudioData = ( note.source as AudioLoop ) ? AudioLoop( note.source ).sample : note.source;
			
			if ( constant && inverted )
			{
				_wave_id = waves.createConstAndInvertedWIfNotExists( description.id, source );
			}
			else if ( constant )
			{
				_wave_id = waves.createConstWIfNotExists( description.id, source );
			}
			else if ( inverted )
			{
				_wave_id = waves.createInvertedWIfNotExists( description.id, source );
			}
			else
			{
				_wave_id = waves.createWIfNotExists( description.id, source );
			}	
			
			wave = waves.attachW( _wave_id );
			
			if ( wave.needUpdate && ! wave.rendering )
			{
				if ( update )
				{
					waves.commitUpdate();
				}	
			}
			else 
			{
				_needRecalc = true;
			}	
			
			wave.addEventListener( Event.CHANGE, onChangedWave );
		}
		
		public function updateWave() : void
		{	
			waves.updateW( wave );
		}
		
		public function get selected() : Boolean
		{
			return _selected;
		}
		
		public function set selected( value : Boolean ) : void
		{
			if ( value != _selected )
			{
				_selected = value;
				invalidateAndTouchDisplayList();
			}	
		}
		
		public function get hovered() : Boolean
		{
			return _hovered;
		}
		
		public function set hovered( value : Boolean ) : void
		{
			if ( value != _hovered )
			{
				_hovered = value;
				invalidateAndTouchDisplayList();
			}	
		}	
		
		private function pushData( x : Number, w : Number, leftRounded : Boolean, rightRounded : Boolean ) : void
		{
			var rX : Number = _cornerRadius < w - _cornerRadius / 2 ? _cornerRadius : w / 2;
			
			//Верхний левый
			if ( leftRounded )
			{
			    _commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_data[ _di ++ ] = x;
				_data[ _di ++ ] = _cornerRadius;
				
				_commands[ _ci ++ ] = GraphicsPathCommand.CURVE_TO;
				_data[ _di ++ ] = x;
				_data[ _di ++ ] = 0;
				_data[ _di ++ ] = x + rX;
				_data[ _di ++ ] = 0;
				
				
				
			}
			else
			{
				_commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_data[ _di ++ ] = x;
				_data[ _di ++ ] = 0;
			}	
			
			_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
			_data[ _di ++ ] = rightRounded ? x + w - rX : x + w;
			_data[ _di ++ ] = 0;
			
			//Верхний правый
			if ( rightRounded )
			{
				_commands[ _ci ++ ] = GraphicsPathCommand.CURVE_TO;
				_data[ _di ++ ] = x + w;
				_data[ _di ++ ] = 0;
				_data[ _di ++ ] = x + w;
				_data[ _di ++ ] = _cornerRadius;
			}
			
			
			_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
			_data[ _di ++ ] = x + w;
			_data[ _di ++ ] = rightRounded ? contentHeight - _cornerRadius : contentHeight;
			
			//Нижний правый
			if ( rightRounded )
			{
				_commands[ _ci ++ ] = GraphicsPathCommand.CURVE_TO;
				_data[ _di ++ ] = x + w;
				_data[ _di ++ ] = contentHeight;
				_data[ _di ++ ] = x + w - rX;
				_data[ _di ++ ] = contentHeight;
			}
			
			_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
			_data[ _di ++ ] = leftRounded ? x + rX : x;
			_data[ _di ++ ] = contentHeight;
			
			//Нижний левый
			if ( leftRounded )
			{
				_commands[ _ci ++ ] = GraphicsPathCommand.CURVE_TO;
				_data[ _di ++ ] = x;
				_data[ _di ++ ] = contentHeight;
				_data[ _di ++ ] = x;
				_data[ _di ++ ] = contentHeight - _cornerRadius;
			}
			
			_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
			_data[ _di ++ ] = x;
			_data[ _di ++ ] = leftRounded ? _cornerRadius :  0;
			
		}
		
		private function calculateParameters() : void
		{
			//Длина образца слева
			leftLength = _localOffset;
			
			//Общее кол-во "целых" семплов в лупе
			hole       = int( _duration - leftLength ) / int( _loopDuration ) ;
			
			//Остающаяся длина справа
			rightLength = _duration - ( hole * _loopDuration ) - leftLength;	
			
			//rightLength иногда вычисляется не совсем точно, поэтому исправляем ошибку вычисления
			if ( Math.abs( rightLength ) < 0.005 )
			{
				rightLength = 0.0;
			}	
			
			loopWidth = _loopDuration / _scale;
			leftLength = leftLength / _scale;
			rightLength = rightLength / _scale;
		}	
		
		private function draw() : void
		{
			_ci = 0;
			_di = 0;
			
			var _alpha : Number = unselected_alpha;
			
			if ( _selected && _hovered )
			{
				_alpha = selected_and_hovered_alpha;
			}	
			else
			{
				if ( _selected ) _alpha = selected_alpha;
				 else _alpha = hovered_alpha;	
			}
			
			graphics.clear();
			graphics.beginFill( _error ? ColorPalette.ERROR_COLOR : _color, _alpha );	
			
			if ( rightLength >= 0 )
			{
				var x : Number  = 0.0;
				
				//Кусок слева
				if ( leftLength > 0 )
				{
					pushData( x, leftLength, false, true );
					x += leftLength;
				}
				
				//Целые куски
				for ( var i : int = 0; i < hole; i ++ )
				{
					pushData( x, loopWidth, true, true ); 
					x += loopWidth;    
				}
				
				//Кусок справа
				if ( rightLength > 0 )
				{
					pushData( x, rightLength, true, false );
				}
			}	
			else
			{
				pushData( 0, contentWidth, false, false );
			}	

			if ( _ci < _commands.length )
			{
			  _commands.splice(_ci, _commands.length - _ci);
			  _data.splice(_di, _data.length - _di);
			}
				
			graphics.drawPath( _commands, _data );
			
			graphics.endFill();
		}
		
		private function putParts( x : Number, parts : Vector.<BitmapData> ) : void
		{
			var i : int = 0;
			var bitmap : Bitmap
			
			while( i < parts.length )
			{
				bitmap = new Bitmap( parts[ i ], 'auto', true );
				bitmap.x = x;
				
				_waveContainer.addChild( bitmap );
				x += bitmap.width;
				i ++;
			}
		}
		
		private function drawSoundWave() : void
		{
			var i : int = 0;
	
			//Удаляем предыдущие волны
			while( _waveContainer.numChildren > 0 )
			{
				_waveContainer.removeChildAt( _waveContainer.numChildren - 1 );
			}	
			
			if ( rightLength >= 0 )
			{
				var x : Number  = 0.0;	
				
				if ( leftLength > 0 )
				{
					var b : Number = contentWidth - Math.floor( contentWidth );
					
					//trace( wave.w, loopWidth );
					putParts( x, wave.copy( Math.round( loopWidth - leftLength ),  leftLength + b ) );
					x += leftLength;
				}
				
				//Целые куски
				while( i < hole )
				{
					putParts( x, wave.copy( 0, loopWidth ) ); 
					x += loopWidth;
					i ++;
				}
				
				//Кусок справа
				if ( rightLength > 0 )
				{
					putParts( x, wave.copy( 0, rightLength ) );	
				}
			}	
			else
			{
				putParts( x, wave.copy( Math.round( loopWidth - leftLength ), leftLength + rightLength ) );	
			}
			
			//trace( contentWidth - x );
		}	
		
		/**
		 * Вкл\выкл индикатор состояния загрузки 
		 * @return 
		 * 
		 */		
		public function get loading() : Boolean
		{
			return _loading;
		}
		
		public function set loading( value : Boolean ) : void
		{
			if ( _loading != value )
			{
				_loading = value;
				
				//Если сейчас состояние ошибки, то отключаем его
				if (  _error )
				{
					setErrorState( ! _loading );
				}
				
				setLoadingState( _loading );
			}	
		}
		
		private function setLoadingState( value : Boolean ) : void
		{
			if ( value )
			{
				if ( ! loaderIndicator )
				{
					loaderIndicator = new Preloader();
					loaderIndicator.alpha = 0.75;
					loaderIndicator.touch();
					loaderIndicator.addEventListener( MouseEvent.CLICK, onIndicatorClick );
					
					addChild( loaderIndicator );
				}
			}
			else if ( loaderIndicator )
			{
				loaderIndicator.removeEventListener( MouseEvent.CLICK, onIndicatorClick );
				removeChild( loaderIndicator );
				loaderIndicator = null;
			}
		}
		
		/**
		 * Отображает прогресс операции, в состоянии загрузки 
		 * @param value
		 * @param total
		 * 
		 */		
		public function setProgress( value : int, total : int ) : void
		{
			if ( loaderIndicator )
			{
				loaderIndicator.setProgress( value, total );
			}
		}
		
		public function get error() : Boolean
		{
			return _error;
		}
		
		public function set error( value : Boolean ) : void
		{
			if ( _error != value )
			{
				_error = value;
				
				//Если сейчас состояни ошибки, то отключаем состояние загрузки
				if ( _loading )
				{
					setLoadingState( ! _error );
				}
				
				setErrorState( _error );
				
				invalidateDisplayList();
			}
		}
		
		private function setErrorState( value : Boolean ) : void
		{
			if ( value )
			{
				if ( ! errorButton )
				{
					errorButton = new ErrorButton();
					errorButton.alpha = 0.75;
					errorButton.touch();
					errorButton.addEventListener( MouseEvent.CLICK, onErrorButtonClick );
					
					addChild( errorButton );
				}
			}
			else if ( errorButton )
			{
				errorButton.removeEventListener( MouseEvent.CLICK, onIndicatorClick );
				removeChild( errorButton );
				errorButton = null;
			}
		}
		
		private function onErrorButtonClick( e : MouseEvent ) : void
		{
			var p : Point = globalToLocal( new Point( e.stageX, e.stageY ) );
			dispatchEvent( new MouseEvent( 'errorButtonClick', e.bubbles, e.cancelable, p.x, p.y, e.relatedObject ) );
		}
		
		private function onIndicatorClick( e : MouseEvent ) : void
		{
			var p : Point = globalToLocal( new Point( e.stageX, e.stageY ) );
			dispatchEvent( new MouseEvent( 'indicatorClick', e.bubbles, e.cancelable, p.x, p.y, e.relatedObject ) );
		}
		
		private function onChangedWave( e : Event ) : void
		{
			if ( parent )
			{	
				_waveContainer.visible = true;
				drawSoundWave();	
			}
		}	
		
		override protected function update() : void
		{
			if ( wave )
			{
				_waveContainer.visible = ! wave.needUpdate; //Вкл\выкл видимость волны
			}	
			
			if ( _needRecalc )
			{
				calculateParameters();
				
				if ( _waveContainer.visible )
				{
					drawSoundWave();
				}	
				
				_needRecalc = false;
			}
			
			draw();
			
			if ( description )
			{
				label.text  = description.name;
			}	
		}
		
		override public function clone() : BaseVisualSample
		{
			var vs : VisualSample = new VisualSample();
			    vs.scale = _scale;
				vs.contentHeight = contentHeight;
			    vs.position = _position;
			    vs.trackNumber = _trackNumber;
			    vs.loopDuration = _loopDuration;
			    vs.duration = _duration; 
			    vs.offset = _offset;
				vs.description = description;
				
				if ( _loading )
				{
					vs.loading = true;
				}
				
				if ( _error )
				{
					vs.error = true;
				}
				
				if ( note )
				{
					vs.note = note.clone();
					
					var loop : AudioLoop = AudioLoop( vs.note.source );
					
					if ( loop.sample as AudioData )
					{
						vs.attachToWave( ! loop.loop, loop.inverted );
					}	
				}
				
			return vs;	
		}
	}
}