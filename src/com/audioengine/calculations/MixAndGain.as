package com.audioengine.calculations
{
	import com.audioengine.core.AudioData;
	
	import flash.display.Shader;
	import flash.utils.ByteArray;
	
	import pbjAS.PBJ;
	import pbjAS.PBJAssembler;
	import pbjAS.PBJParam;
	import pbjAS.PBJType;
	import pbjAS.ops.OpAdd;
	import pbjAS.ops.OpDiv;
	import pbjAS.ops.OpLoadFloat;
	import pbjAS.ops.OpMov;
	import pbjAS.ops.OpMul;
	import pbjAS.ops.OpSampleNearest;
	import pbjAS.params.Parameter;
	import pbjAS.params.Texture;
	import pbjAS.regs.RFloat;

	public class MixAndGain extends Calculation
	{
		private static const DEFAULT_VOLUME : Number = Settings.DEFAULT_TRACK_SOUND_VOLUME;
		private static const DEFAULT_LEFT   : Number = 1.0;
		private static const DEFAULT_RIGHT  : Number = 1.0;
		
		/**
		 * Данные дорожек для смешивания 
		 */		
		private var _tracks     : Vector.<ByteArray>;
		
		/**
		 * Значение панорам дле левых каналов дорожек 
		 */		
		private var _leftPans   : Vector.<Number> = new Vector.<Number>();
		
		/**
		 * Значение панорам для правых дорожек 
		 */		
		private var _rightPans  : Vector.<Number> = new Vector.<Number>();
		
		/**
		 * Значения громкости звучания дорожек 
		 */		
		private var _volumes    : Vector.<Number> = new Vector.<Number>();
		
		/**
		 * Режим "Моно" вкл\выкл 
		 */		
		private var _mono       : Vector.<Boolean> = new Vector.<Boolean>();
		
		/**
		 * Количество каналов в режиме "Моно" 
		 */		
		private var _enabledChannels : int;
		
		/**
		 * Номер канала работающего в режиме "соло"
		 * -1 - если нет такого канала 
		 */		
		private var _soloChannel : int = -1;
		
		private const empty : ByteArray = new ByteArray();
		
		public function MixAndGain(length:int=0)
		{
			super(length);
			empty.length = AudioData.framesToBytes( _length );
		}
		
		override public function set length(value:int) : void
		{
			super.length = value;
			empty.length = AudioData.framesToBytes( _length );
		}	
		
		public function get tracks() : Vector.<ByteArray>
		{
			return _tracks;
		}	
			
		public function set tracks( value : Vector.<ByteArray> ) : void
		{
				_tracks = value;
				_propertyChanged = true;
				_needRebuild = true;
		}
		
		/**
		 * Возвращает количество включенных каналов 
		 * @return 
		 * 
		 */		
		public function get enabledChannels() : int
		{
			if ( _tracks.length == 0 ) return 0;
			
			return _soloChannel == -1 ? _enabledChannels : 1;
		}
		
		/**
		 * Возвращает количество включенных каналов 
		 * @return 
		 * 
		 */		
		public function get disabledChannels() : int
		{
			if ( _tracks.length == 0 ) return 0;
			
			return _soloChannel == -1 ? _tracks.length - _enabledChannels :
				                        _tracks.length == 1 ? 0 : _tracks.length - 1;
		}	
		
		public function addControlAt( index : int = -1 ) : void
		{
		  if ( index == -1 ) index = _tracks.length;
		  
		  _volumes.splice( index, 0, index );
		  _leftPans.splice( index, 0, 1 );
		  _rightPans.splice( index, 0, 1 );
		  _mono.splice( index, 0, 1 );
		  
		  _volumes[ index ]   = DEFAULT_VOLUME;
		  _leftPans[ index ]  = DEFAULT_LEFT;
		  _rightPans[ index ] = DEFAULT_RIGHT;
		  _mono[ index ]      = false;
		  
		  _enabledChannels ++;
		  
		  _propertyChanged = true;
		  _needRebuild = true;
		}
		
		public function removeControlAt( index : int = -1 ) : void
		{
			if ( index == -1 ) index = _tracks.length - 1;
			
			_volumes.splice( index, 1 );
			_leftPans.splice( index, 1 );
			_rightPans.splice( index, 1 );
			
			if ( ! _mono[ index ] )
			{
				_enabledChannels --;
			}
				
			_mono.splice( index, 1 );
			
			_propertyChanged = true;
			_needRebuild = true;
		}
		
		public function moveChannels( fromIndex : int, toIndex : int ) : void
		{
			var v : Vector.<Number> = _volumes.splice( fromIndex, 1 );
			_volumes.splice( toIndex, 0, v[ 0 ] );
			
			v = _leftPans.splice( fromIndex, 1 );
			_leftPans.splice( toIndex, 0, v[ 0 ] );
			
			v = _rightPans.splice( fromIndex, 1 );
			_rightPans.splice( toIndex, 0, v[ 0 ] );
			
			var b : Vector.<Boolean> = _mono.splice( fromIndex, 1 );
			_mono.splice( toIndex, 0, b[ 0 ] );
			
			if ( _soloChannel != -1 )
			{
				if ( fromIndex == _soloChannel )
				{
					_soloChannel = toIndex;
				}
				else
				{
					_soloChannel += fromIndex < toIndex ? -1 : 1;
				}		
			}
			
			_propertyChanged = true;
		}	
		
		public function swapChannels( index1 : int, index2 : int ) : void
		{
			var buf : Number   = _volumes[ index1 ];
			_volumes[ index1 ] = _volumes[ index2 ];
			_volumes[ index2 ] = buf;
			
			buf                 = _leftPans[ index1 ];
			_leftPans[ index1 ] = _leftPans[ index2 ];
			_leftPans[ index2 ] = buf;
			
			buf                 = _rightPans[ index1 ];
			_rightPans[ index1 ]= _rightPans[ index2 ];
			_rightPans[ index2 ]= buf;
			
			var buf2 : Boolean = _mono[ index1 ];
			_mono[ index1 ] = _mono[ index2 ];
			_mono[ index2 ] = buf2;
			
			if ( _soloChannel != -1 )
			{
				if ( index1 == _soloChannel )
				{
					_soloChannel = index2;
				}
				else if ( index2 == _soloChannel )
				{
					_soloChannel = index1;
				}		
			}
			
			_propertyChanged = true;
		}	
		
		public function getMonoAt( channelNumber : uint ) : Boolean
		{
			return _mono[ channelNumber ];
		}
		
		public function setMonoAt( channelNumber : uint, value : Boolean ) : void
		{
		  if ( _mono[ channelNumber ] != value )
		  {
			  _mono[ channelNumber ] = value;
			  
			  if ( value ) _enabledChannels --;
			   else _enabledChannels ++;
			  
			  _propertyChanged = true;
			  _needRebuild = true;
		  }	  
		}
		
		/**
		 * Номер канала работающего в режиме solo 
		 * @return 
		 * 
		 */		
		public function get soloChannel() : int
		{
			return _soloChannel;
		}
		
		public function set soloChannel( channelNumber : int ) : void
		{
			if ( channelNumber != _soloChannel )
			{
				_soloChannel = channelNumber;
				
				_propertyChanged = true;
				_needRebuild = true;
			}	
		}	
		
		public function getLeftPanAt( channelNumber : uint ) : Number
		{
			return _leftPans[ channelNumber ];
		}
		
		public function setLeftPanAt( channelNumber : uint, value : Number ) : void
		{
		   if ( _leftPans[ channelNumber ] != value )
		   {
			   _leftPans[ channelNumber ] = value;
			   _propertyChanged = true;
		   }  
		}
		
		public function getRightPanAt( channelNumber : uint ) : Number
		{
			return _rightPans[ channelNumber ];
		}
		
		public function setRightPanAt( channelNumber : uint, value : Number ) : void
		{
			if ( _rightPans[ channelNumber ] != value )
			{
				_rightPans[ channelNumber ] = value;
				_propertyChanged = true;
			}	
		}
		
		public function getPan( channelNumber : uint ) : Number
		{
			var left  : Number = _leftPans[ channelNumber ]; 
			var right : Number = _rightPans[ channelNumber ];
			
			if ( left == 1.0 && right == 1.0 ) return 0.0
			if ( left == 1.0 ) return 1.0 - right;
			if ( right == 1.0 ) return left - 1.0;
			
			return NaN;
		}
		
		/**
		 * Устанавливает значение стереопанорамы для дорожки -1..1 
		 * @param channelNumber номер дорожки
		 * @param value значение стереопонорамы
		 * 
		 */		
		public function setPan( channelNumber : uint, value : Number ) : void
		{
			if ( value == 0.0 )
			{
				_leftPans[ channelNumber ]  = 1.0;
				_rightPans[ channelNumber ] = 1.0;
				
				_propertyChanged = true;
			}
			else
			{
				if ( value > 0.0 )
				{
					_leftPans[ channelNumber ]  = ( 1.0 - value );
					_rightPans[ channelNumber ]   = 1.0;
				}
				else
				{
					_rightPans[ channelNumber ]   = ( value + 1.0 );
					_leftPans[ channelNumber ]  = 1.0;
				}
				
				_propertyChanged = true;
			}	
		}
		
		public function getVolumeAt( channelNumber : uint ) : Number
		{
			return _volumes[ channelNumber ];
		}
		
		public function setVolumeAt( channelNumber : uint, value : Number ) : void
		{
			if ( _volumes[ channelNumber ] != value )
			{
				_volumes[ channelNumber ]   = value; 
				_propertyChanged = true;
			}	
		}	
		
		//Добавляет код для указанного канала
		private function addCodeFor( pbj : PBJ, cNumber : uint ) : void
		{
			//Образцы для входа
			pbj.parameters.push( new PBJParam( 'sample' + cNumber, new Texture( 2, cNumber ) ) );
			
			//Множитель каналов (регистр 3..n )
			pbj.parameters.push( new PBJParam( 'multiplier' + cNumber, new Parameter( PBJType.TFloat2, false, new RFloat( cNumber + 5, _channels ) ) ) );
			
			//Код для смешивания этого образца
			pbj.code.push( new OpSampleNearest( new RFloat( 2, _channels ), new RFloat( 0, _channels ), cNumber ) ); // v3 = t(i);
			pbj.code.push( new OpMul( new RFloat( 2, _channels ), new RFloat( cNumber + 5, _channels ) ) ); //v3 *= multiplier[ i + 3 ] 
			
			if ( cNumber == 0 )
			{
				pbj.code.push( new OpMov( new RFloat( 3, _channels ), new RFloat( 2, _channels ) ) ); // output = v3;
			}
			else
			{
				pbj.code.push( new OpAdd( new RFloat( 3, _channels ), new RFloat( 2, _channels ) ) ); // output = output + v3;
			}
		}	
		
		override protected function buildShader():void
		{
		  if ( _enabledChannels > 0 )
		  {
			  super.buildShader();
			  
			  var pbj : PBJ = createPBJ( 'mixAndGainTask' );
			  
			  /*
			  регистр 2,3,4 промежуточный буфер
			  */
			  
			  if ( _soloChannel == -1 )
			  {
				  var i  : int = 0;
				  var cNumber : int = 0;
				  
				  while( i < _tracks.length )
				  {
					  if ( ! _mono[ i ] )
					  {	
						  addCodeFor( pbj, cNumber );
						  
						  cNumber ++;
					  }
					  
					  i ++;
				  } 
			  }	   
			  else
			  {
				  addCodeFor( pbj, 0 );
			  }	  
			  
			  
			  /*if ( _tracks.length > 1 )
			  {*/
			  pbj.code.push( new OpLoadFloat( new RFloat( 4, _channels ), 2.0 ) );
			  pbj.code.push( new OpDiv( new RFloat( 3, _channels ), new RFloat( 4, _channels ) ) );
			  //}	
			  
			  pbj.code.push( new OpMov( new RFloat( 1, _channels ), new RFloat( 3, _channels ) ) ); 
			  
			  //Добавляем выход
			  addOutput( pbj, 1 );
			  
			  //Собираем Shader
			  _shader = new Shader( PBJAssembler.assemble( pbj ) ); 
		  }	  
		}
		
		override public function calculate( data : ByteArray ) : void
		{
			if ( _enabledChannels > 0 )
			{
				super.calculate( data );
				return;
			}
			
			//Заполняем буфер нулями	
			data.position = 0;
			data.writeBytes( empty );
		}	
		
		override protected function propertyChanged() : void
		{
			super.propertyChanged();
			
			//Режим "Соло" отключен
			if ( _soloChannel == -1 )
			{
				var i           : int = 0;
				var сNumber     : int = 0;
				
				//Устанавливаем входные параметры
				if ( _enabledChannels > 0 )
				{
					while( i < _tracks.length )
					{
						if ( ! _mono[ i ] )
						{	
							setData( 'sample' + сNumber, _tracks[ i ] );
							setValue( 'multiplier' + сNumber, [ _leftPans[ i ] * _volumes[ i ], _rightPans[ i ] * _volumes[ i ] ] );
							
							сNumber ++;
						}
						
						i ++;
					}
				}
				
				return;
			}	
			
			//Режим "Соло"
			setData( 'sample' + 0, _tracks[ _soloChannel ] );
			setValue( 'multiplier' + 0, [ _leftPans[ _soloChannel ] * _volumes[ _soloChannel ], _rightPans[ _soloChannel ] * _volumes[ _soloChannel ] ] );	
		}
	}
}