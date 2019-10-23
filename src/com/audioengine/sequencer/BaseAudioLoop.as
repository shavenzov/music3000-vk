package com.audioengine.sequencer
{
	import com.audioengine.calculations.Invert;
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IAudioData;
	import com.audioengine.core.TimeConversion;
	import com.audioengine.sources.Routines;
	import com.audioengine.utils.SoundUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	public class BaseAudioLoop extends EventDispatcher implements IAudioData
	{
		/**
		 * Заблокировано 
		 */		
		private var _locked : Boolean;
		
		/**
		 * Семпл является инвертированным 
		 */		
		private var _inverted : Boolean;
		
		/**
		 * Ссылка на размещение в памяти исходного образца 
		 */		
		protected var original : IAudioData;
		
		/**
		 * Значение меняется в зависимости от св-ва loop 
		 */		
		protected var originalLength : Number;
		
		/**
		 * Остаток справа если семпл обрезан при loop=true 
		 */		
		private var loopOffset : Number;
		
		/**
		 *Смещение фазы семпла в фреймах
		 */	
		protected var _offset : Number = 0.0;
		
		/**
		 * Длина "Петли" в фреймах 
		 */		
		protected var _length : Number;
		
		/**
		 * Темп семпла 
		 */		
		protected var _bpm : Number;
		
		/**
		 * Воспринимать ли семпл как петлю 
		 */		
		protected var _loop : Boolean;
		
		public function BaseAudioLoop( sample : IAudioData, bpm : Number = NaN, loop : Object = null )
		{
			original = sample;
			original.addEventListener( Event.CHANGE, onSourceChanged );
			
			_loop = loop == null ? sample.loop : Boolean( loop );
			_bpm = isNaN( bpm ) ? sample.bpm : bpm;
			_locked = original.locked;
			
			originalLength = getLoopLength();
			loopOffset = original.length - originalLength;
			
			_length = originalLength;
			
			_needRecalculate = true;
		}
		
		public function dispose() : void
		{
			original.removeEventListener( Event.CHANGE, onSourceChanged );
		}	
		
		private function onSourceChanged( e : Event ) : void
		{
		 _length = originalLength = getLoopLength();
		 originalLengthChanged();
		 dispatchEvent( e );
		}
		
		protected function originalLengthChanged() : void
		{
			
		}	
		
		public function get bpm() : Number
		{
			return _bpm;
		}	
		
		public function get locked() : Boolean
		{
			return _locked;
		}
		
		public function set locked( value : Boolean ) : void
		{
			_locked = value;
		}	
		
		public function get data() : ByteArray
		{
			return original.data;
		}
		
		public function get sample() : IAudioData
		{
			return original;
		}	
		
		/**
		 * Предварительно просчитанные параметры, необходимо перерасчитывать при изменении duration и offset 
		 */		
		
		//Длина образца слева
		private var leftLength : Number;
		//Остающееся смещениие слева
		private var left : Number;
		//Общее кол-во "целых" семплов в лупе
		private var hole  : Number;
		//Общая длина отрезка состоящего из целых семплов
		private var holeLength : Number;
		//Остающаяся длина справа
		private var rightLength : Number;
		//Необходимо пересчитать данные
		private var _needRecalculate : Boolean;
		
		private function calculateParams() : void
		{
			//Длина образца слева
			leftLength = Math.round( - _offset + Math.ceil( _offset / originalLength ) * originalLength ); 
			
			//Остающееся смещениие слева
			left = originalLength - leftLength;
			
			//Общее кол-во "целых" семплов в лупе
			hole = Math.floor( ( _length - leftLength  ) / originalLength );
			holeLength = hole * originalLength;
			
			//Остающаяся длина справа
			rightLength = Math.floor( _length - leftLength - holeLength );
		}
		
		private function getLoopLength() : Number
		{
		  if ( ! original.loop || ! _loop ) return original.length - original.loaderAddition;
			
		  return Routines.floorLength( original.length, original.bpm );
		}	
		
		public function get id() : String
		{
			return original.id;
		}
		
		public function get loaderAddition() : Number
		{
			return original.loaderAddition;
		}
		
		public function get loop() : Boolean
		{
			return _loop;
		}
		
		public function set loop( value : Boolean ) : void
		{
			if ( _loop != value )
			{
				_loop = value;
				
				var newLength : Number = getLoopLength();
				var k : Number = newLength / originalLength; 
				
				_length = Math.round( k * _length );
				_offset = Math.round( k * _offset );
				
				originalLength = newLength;	
				loopOffset = original.length - originalLength;
				
				_needRecalculate = true;
				
				dispatchEvent( new Event( Event.CHANGE ) );
			}	
		}
		
		public function get inverted() : Boolean
		{
			return _inverted;
		}
		
		public function set inverted( value : Boolean ) : void
		{
			if ( _inverted != value )
			{
				_inverted = value;
				dispatchEvent( new Event( Event.CHANGE ) );
			}	
		}	
		
		public function copy( buffer : ByteArray, srcOffset : Number, dstOffset : Number, length : Number, params : Object = null ) : void
		{
			if ( _needRecalculate ) 
			{
				calculateParams();
				_needRecalculate = false;
			}	
			
			//trace( 'audioLoop', originalLength, _length, srcOffset, dstOffset, length );
			
			var remaining    : Number = length;
			var cLength      : Number;
			var cOffset      : Number = dstOffset;
			var sOffset      : Number = srcOffset;
			var invertOffset : Number = _inverted ? loopOffset : 0.0; //Компенсируем смещение при инвертировании при loop=true
			var i : int = 0;
			
			//Копируем образец слева
			if ( leftLength > 0 )
			{
				if ( sOffset < leftLength )
				{
					cLength = leftLength >= sOffset + remaining ? remaining : leftLength - sOffset; 
					original.copy( buffer, left + sOffset + invertOffset, cOffset, cLength, _inverted );
					
					remaining -= cLength;
					cOffset += cLength;
					sOffset += cLength;	
				}
			}	
			
			//Копируем образец из целого куска и из стыков между целыми кусками
			if ( remaining > 0 )
			if ( sOffset < leftLength + holeLength )
			{
				while( i < hole )
				{
					var cL : Number = leftLength + originalLength * ( i + 1 );
					
					if ( sOffset < cL )
					{
						cLength = cL >= sOffset + remaining ? remaining : cL - sOffset;
						original.copy( buffer, ( originalLength - ( cL - sOffset ) ) + invertOffset, cOffset, cLength, _inverted );
						
						remaining -= cLength;
						cOffset += cLength;
						sOffset += cLength;
						
						if ( remaining == 0 ) break;
					}	
					
					i ++;
				}	
			}	
			
			//Копируем образцы справа
			if ( remaining > 0 )
			{
				if ( sOffset < _length )
				{
					cLength = rightLength >= remaining ? remaining : rightLength - ( _length - sOffset );
					original.copy( buffer, ( sOffset - holeLength - leftLength ) + invertOffset, cOffset, remaining, _inverted ); 
				}	
			}
			
			//Инвертируем блок данных, если это необходимо
			/*if ( _inverted )
			{
				var subBuffer : ByteArray = new ByteArray();
				    subBuffer.writeBytes( buffer, AudioData.framesToBytes( dstOffset ), AudioData.framesToBytes( length ) );
				
				var result : ByteArray = new ByteArray();	
					
				_invertor.length = length;
				_invertor.input = subBuffer;
				_invertor.calculate( result );
				
				buffer.position = AudioData.framesToBytes( dstOffset );
				buffer.writeBytes( result );
				
				//SoundUtils.traceByteArray( buffer );
			}*/	
		}
		
		public function clear() : void
		{
			throw new Error( 'This object is read only.' );
		}	
		
		public function get offset() : Number
		{
			return _offset;
		}
		
		public function set offset( value : Number ) : void
		{
			_offset = value;
			_needRecalculate = true;
		}
		
		public function get timeOffset() : Number
		{
			return TimeConversion.numSamplesToSeconds( _offset );
		}
		
		public function set timeOffset( value : Number ) : void
		{
			offset =  TimeConversion.secondsToNumSamples( value );
		}	
		
		public function get length() : Number
		{
			return _length
		}
		
		public function set length( value : Number ) : void
		{
			_length = value;
			_needRecalculate = true;
			dispatchEvent( new Event( Event.CHANGE ) );
		}
		
		public function get timeLength() : Number
		{
			return TimeConversion.numSamplesToSeconds( _length );
		}
		
		public function set timeLength( value : Number ) : void
		{
			length = TimeConversion.secondsToNumSamples( value );
		}	
		
		public function clone() : IAudioData
		{
			var l : BaseAudioLoop = new BaseAudioLoop( original );
			
			if ( ( _offset != 0 ) || ( _length != original.length ) )
			{
				l.offset = _offset;
				l.length = _length;
			}		
				
			return l;	
		}
	}
}