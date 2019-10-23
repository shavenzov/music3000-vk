/**
 * Задний фон Шкалы времени 
 */
package components.sequencer.timeline
{
	import classes.Sequencer;
	
	import com.audioengine.processors.Mixer;
	
	import components.ScrollableBase;
	import components.sequencer.ColorPalette;
	
	import flash.display.GraphicsPathCommand;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import mx.core.FTETextField;

	public class HGrid extends ScrollableBase
	{
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
		 * Отображать ли надпись "Брось сюда семпл" 
		 */		
		private var _showHint : Boolean = false;
		
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
		 * Количество отображаемых дорожек 
		 */		
		private var _numTracks : int = 15;
		private var _numTracksChanged : Boolean;
		
		/**
		 * Высота каждой из дорожек 
		 */		
		public var _trackHeight : Number = 74.15;
		
		/**
		 * Номер выбранной дорожки 
		 */		
		private var _selectedTrack : int = -1;
		
		/**
		 * Номер дорожки над которой сейчас находится курсор 
		 */		
		private var _highlightedTrack : int = -1;
		
		/**
		 * Надпись для создания дорожки перенесите семпл сюда 
		 */		
		private var _labelDropSampleHere : FTETextField;
		
		/**
		 * Логотип 
		 */		
		private var _logo : Sprite;
		
		/**
		 * Размер по вертикали занимаемый дорожками секвенвора 
		 */		
		private var _tracksContentHeight : Number;
		
		/**
		 * Для определяения, какая дорожка сейчас отключена 
		 */		
		private var _mixer : Mixer;
		
		public function HGrid()
		{
			super();
			
			_mixer = classes.Sequencer.impl.mixer;
			
			cacheAsBitmap = true;
			
			_labelDropSampleHere = new FTETextField();
			_labelDropSampleHere.autoSize = TextFieldAutoSize.CENTER   
			_labelDropSampleHere.embedFonts = true; 
			_labelDropSampleHere.mouseEnabled = false;
			
			addChild( _labelDropSampleHere );
		}
		
		public function highlightTrack( number : int ) : void
		{
			if ( number != _highlightedTrack )
			{
				_highlightedTrack = number;
				
				/*if ( number > -1 )
				{
					redrawHighlight( _highlight, determineColor( number ), 0.25 );
					updateHighlight( _highlight, number );
					_highlight.visible = true;
				}	
				else
				{
					_highlight.visible = false;
				}*/
				invalidateAndTouchDisplayList();
			}	
		}
		
		public function selectTrack( number : int ) : void
		{
			if ( number != _selectedTrack )
			{
				_selectedTrack = number;
				/*
				if ( number > -1 )
				{
					redrawHighlight( _select, determineColor( number ), 0.35 );
					updateHighlight( _select, number );
					_select.visible = true;
				}	
				else
				{
					_select.visible = false;
				}*/
				
				invalidateAndTouchDisplayList();
			}	
		}
		
		/**
		 * Количество отображаемых дорожек 
		 */
		public function get numTracks() : int
		{
			return _numTracks;
		}
		
		public function set numTracks( value : int ) : void
		{
			if ( _numTracks != value )
			{
				_numTracks = value;
				
				if ( _selectedTrack >= _numTracks )
				{
					_selectedTrack = -1;
				}
				
				if ( _highlightedTrack >= _numTracks )
				{
					_highlightedTrack = -1;
				}	
				
				_needMeasure = true;
				_needUpdate = true;
				_numTracksChanged = true;
			}	
		}
		
		public function get showHint() : Boolean
		{
			return _showHint;
		}
		
		public function set showHint( value : Boolean ) : void
		{
			_showHint = value;
			_needMeasure = true;
			_needUpdate = true;
		}	
		
		override protected function measure():void
		{
			_tracksContentHeight = _numTracks * _trackHeight;
			
			if ( _showHint )
			{
				if ( ( _numTracks > 0 ) && ( _numTracks < TimeLineParameters.MAX_NUM_TRACKS ) )
				{
					contentHeight = _tracksContentHeight + _trackHeight;
				}
				else
				{
					contentHeight = _tracksContentHeight;
				}	
			}	
			else
			{
				contentHeight = _tracksContentHeight;
			}	
		}	
		
		private function draw( w : Number, h : Number ) : void
		{
			//Отрисовываем
			graphics.clear();
			
			_ci = 0;
			_di = 0;
			
			var i : int = 1;
			var y : Number;
			//var m : Matrix = new Matrix();
			
			//m.createGradientBox( w, _trackHeight, Math.PI / 2 )
			
			//graphics.beginGradientFill( GradientType.LINEAR, [ 0x000000, 0x2C2B2B, 0x4A4949, 0xFFFFFF ], [ 0.2, 0.3, 0, 0 ], [ 0, 26, 100, 200 ], m, SpreadMethod.REPEAT );
			
			//graphics.drawRect( 0, 0, w, _trackHeight );
			
			while( i <= _numTracks )
			{
				y = i * _trackHeight;
				
				_commands[ _ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_data[ _di ++ ] = 0;
				_data[ _di ++ ] = y;
				
				_commands[ _ci ++ ] = GraphicsPathCommand.LINE_TO;
				_data[ _di ++ ] = w;
				_data[ _di ++ ] = y;
				
				i ++;
				
				/*if ( i < _numTracks )
				{
					graphics.drawRect( 0, y, w, _trackHeight );
				}*/	
			}
			
			//graphics.endFill();
			
			if ( _ci < _commands.length )
			{
				_commands.splice(_ci, _commands.length - _ci);
				_data.splice(_di, _data.length - _di);
			}
			
			//Сетка
			graphics.lineStyle( _divisionWeight, _divisionColor, _divisionAlpha );
			graphics.drawPath( _commands, _data );
			
			//Прозрачный прямоугольник
			graphics.lineStyle();
			graphics.beginFill( 0x00FF00, 0.0 );
			graphics.drawRect( 0.0, 0.0, w, h );
			graphics.endFill();
		}
		
		private function drawSelection( trackNumber : int, color : uint, alpha : Number ) : void
		{
			if ( _mixer.soloChannel != -1 )
			{
				if ( trackNumber != _mixer.soloChannel )
				{
					return;
				}	
			}
			else if ( _mixer.getMonoAt( trackNumber ) )
			{
				return;
			}
			
			graphics.beginFill( color, alpha );
			graphics.drawRect( 0.0, trackNumber * _trackHeight, contentWidth, _trackHeight );
			graphics.endFill();
		}	
		
		private function updateSelection() : void
		{
			if ( _mixer.disabledChannels > 0 )
			{
				var i : int = 0;
				
				graphics.lineStyle();
				graphics.beginFill( ColorPalette.DISABLED_COLOR, 0.25 );
				
				if ( _mixer.soloChannel == -1 ) //Режим выделения "Моно"
				{
					while( i < _mixer.numChannels )
					{
						if ( _mixer.getMonoAt( i ) )
						{
							graphics.drawRect( 0.0, i * _trackHeight, contentWidth, _trackHeight );
						}
						
						i ++;
					}
				}
				else  //Режим выделеения "Соло"
				{
					while( i < _mixer.numChannels )
					{
						if ( _mixer.soloChannel != i )
						{
							graphics.drawRect( 0.0, i * _trackHeight, contentWidth, _trackHeight );
						}
						
						i ++;
					}
				}	
				
				graphics.endFill();
			}
			
			if ( _selectedTrack != -1 )
			{
				//graphics.lineStyle( 0.0, 0x000000 );
				drawSelection( _selectedTrack, ColorPalette.getColor( _selectedTrack ), 0.35 );
			}
			
			if ( _highlightedTrack != -1 )
			{
				graphics.lineStyle();
				drawSelection( _highlightedTrack, ColorPalette.getColor( _highlightedTrack ), 0.25 );
			}
		}	
		
		private function updateHighlight( h : Shape, number : int ) : void
		{
			h.x = 0;
			h.y = number * _trackHeight;
			h.width = contentWidth;
			h.height = _trackHeight;
		}	
		
		override protected function update():void
		{
			if ( _showHint )
			{
				if ( _numTracksChanged )
				{
					if ( _numTracks == 0 )
					{
						_labelDropSampleHere.defaultTextFormat = new TextFormat( 'Calibri', 16, 0xFFFFFF, true );
						_labelDropSampleHere.text = 'Перенеси сюда сэмпл для начала работы...';
						
						if ( ! _logo )
						{
							_logo = new Assets.LOGO();
							addChild( _logo );	
						}
					}
					else
					{
						_labelDropSampleHere.defaultTextFormat = new TextFormat( 'Calibri', 14, 0xFFFFFF, true );
						_labelDropSampleHere.text = 'Перенеси сюда сэмпл для создания дорожки...';
						
						if ( _logo )
						{
							removeChild( _logo );
							_logo = null;
						}
					}
					
					_numTracksChanged = false;
				}	
				
				var emptyH : Number = _scrollHeight - contentHeight;
				
				if ( emptyH > _trackHeight )
				{
					if ( _logo )
					{
						_logo.y = ( emptyH - ( _labelDropSampleHere.height + _logo.height ) )  / 2;
						_labelDropSampleHere.y = _logo.y + _logo.height;
					}
					else
					{
						_labelDropSampleHere.y = _tracksContentHeight + ( emptyH - _labelDropSampleHere.height )  / 2;
					}
				}	
				else
				{
					_labelDropSampleHere.y = _tracksContentHeight + ( _trackHeight - _labelDropSampleHere.height ) / 2;
				}	
				
				if ( _logo )
				{
					_logo.visible = true;
					_logo.x = ( contentWidth - _logo.width ) / 2;
				}
				
				_labelDropSampleHere.x = ( contentWidth - _labelDropSampleHere.width ) / 2;
				_labelDropSampleHere.visible = ( _numTracks < TimeLineParameters.MAX_NUM_TRACKS );
			}
			else
			{
				_labelDropSampleHere.visible = false;
				if ( _logo ) _logo.visible = false;
			}	
			
			if ( _numTracks == 0 )
			{
				graphics.clear();
				return;
			}	
			
			draw( contentWidth, _tracksContentHeight );
			
			updateSelection();
		}
		
		override public function updateScrollRect():void
		{
			if ( _scrollRectChanged )
			{
				update();
			}	
			super.updateScrollRect();
		}
		
		/**
		 * Индекс текущей выбранной дорожки
		 * @return 
		 * 
		 */		
		public function get selectedTrack() : int
		{
			return _selectedTrack;
		}	
	}
}