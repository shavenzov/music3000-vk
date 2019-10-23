package com.audioengine.sequencer
{
	import com.audioengine.calculations.Calculation;
	import com.audioengine.calculations.PitchShift;
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IAudioData;
	import com.serialization.IXMLSerializable;
	
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class AudioLoop extends BaseAudioLoop implements IXMLSerializable
	{
		private static const APPROXI_NUM_SAMPLES : int = 2;
		
		/**
		 * Сдвиг частоты 
		 */		
		private var _rate         : Number;
		/**
		 * Значение длины с учетом сдвига 
		 */		
		private var _scaledLength : Number;
		private var _scaledLoopLength : Number;
		private var _scaledOffset : Number;
		
		/**
		 * Предыдущее положение в буфере во время копирования
		 */
		private var _position : Number = 0.0;
		
		/**
		 * Автоматически подгонять темп источника, под темп AudioLoop 
		 */		
		//private var _autoStretch : Boolean = true;
		
		private var _pitcher      : PitchShift;
		
		public function AudioLoop( sample : IAudioData, bpm : Number = NaN, loop : Object = null )
		{
			super( sample, bpm, loop );
			
			_pitcher = new PitchShift();
			
			calcRate();
			calcLength();
			
			_data = new ByteArray();
			_target = new ByteArray();
		}
		
		override protected function originalLengthChanged():void
		{
			calcLength();
		}	
		
		private function calcRate() : void
		{
			_rate = original.bpm / _bpm;
		}
		
		private function calcLength() : void
		{
			_scaledLength     = _length * _rate;
			_scaledLoopLength = originalLength * _rate;
			_scaledOffset     = _offset * _rate;
		}	
		/*
		public function get rate() : Number
		{
			return _rate;
		}
		
		public function set rate( value : Number ) : void
		{
			_rate = value;
			calcLength();
			
			dispatchEvent( new Event( Event.CHANGE ) );
		}	
		*/
		public function get originalBPM() : Number
		{
			return original.bpm;
		}	
		
		public function set bpm( value : Number ) : void
		{
			_bpm = value;
			calcRate();
			calcLength();
			
			dispatchEvent( new Event( Event.CHANGE ) );
		}	
		
		public function get loopLength() : Number
		{
			return _loop ? _scaledLoopLength : originalLength;
		}	
		
		override public function get offset() : Number
		{
			return _loop ? _scaledOffset : _offset;
		}
		
		override public function set offset( value : Number ) : void
		{
			if ( ! _loop )
			{	
				super.offset = value;
				return;
			}
			
			_scaledOffset = value;
			super.offset = _scaledOffset / _rate;
		}	
		
		override public function get length():Number
		{
			return _loop ? _scaledLength : _length;
		}
		
		override public function set length( value : Number ) : void
		{
			if ( ! _loop )
			{
				super.length = value;
				return;
			}	
			
			_scaledLength = value;
			super.length = _scaledLength / _rate;
		}
		
		override public function set loop( value : Boolean ) : void
		{
			super.loop = value;
			//_autoStretch = value;
			calcLength();
		}
		/*
		public function get autoStretch() : Boolean
		{
		  return _autoStretch;	
		}
		
		public function set autoStretch( value : Boolean ) : void
		{
			_autoStretch = value;
		}	
		*/
		private var _alpha : Number;
		private var _orSrcOffset : Number;
		private var _orLength : Number;
		private var _data : ByteArray;
		private var _target : ByteArray;
		private var _read : int;
		private var _need : int;
		private var _l    : Number;
		private var _r    : Number;
		private var sOffset : int;
		
		override public function copy( buffer : ByteArray, srcOffset : Number, dstOffset : Number, length : Number, params : Object = null ) : void
		{
			_orLength = length / _rate;
			_orSrcOffset = srcOffset / _rate;
			
			length = Math.floor( length );
			
			if ( length > 0 )
			{
				if ( ! _loop || _rate == 1.0 ) 
				{
					if ( length > 0 )
					{
						super.copy( buffer, Math.floor( srcOffset ), Math.round( dstOffset ), length );	
					}
					//else trace( 'Ooops!!!' );
				}
				else
				{
					//Определяем смещение
					_data.position = 0;
					
					//Определяем количество доступных данных для считывания
					sOffset = int( _orSrcOffset );
					_need = Math.ceil( _orLength ) + APPROXI_NUM_SAMPLES;
					_read = ( sOffset + _need ) > int( _length ) ? int( _length ) - sOffset : _need;
					
					/*
					trace( '' );
					trace( 'sample length', _length, _scaledLength, original.length );
					trace( 'length', length, Math.floor( length ), _orLength );
					trace( 'srcOffset', srcOffset, _orSrcOffset );
					trace( 'sOffset', sOffset );
					trace( 'read/need', _read, _need );
					trace( 'buffer.position before', buffer.position, buffer.length );
					trace( params );
					*/
					
					if ( _read > 0 ) //Если длина запрашиваемых данных не ничтожно мала
					{
						_data.length = AudioData.framesToBytes( _read );
						
						super.copy( _data, sOffset, 0.0, _read );
						
						//Добавляем недостающие данные
						if ( _read < _need )
						{
							//trace( 'oops', _read, _need, _data.length / 8 );
							
							_data.position = _data.length - AudioData.BYTES_PER_SAMPLE;
							
							_l = Math.round( _data.readFloat() / 10 ) * 10;
							_r = Math.round( _data.readFloat() / 10 ) * 10;
							
							while( _read < _need )
							{
								_data.writeFloat( _l );
								_data.writeFloat( _r );
								
								_read ++;
							}
						}	
						
						//PixelBender, сможет обработать поток данных за один цикл
						if ( _read <= Calculation.MAX_DATA_WIDTH )
						{
							_alpha = _position - int( _position );
							
							_pitcher.length = _read < length ? int( length ) : _read;
							_pitcher.rate = _rate;
							_pitcher.alpha = _alpha;
							_pitcher.input = _data;
							_pitcher.size =  Math.ceil( _read * _rate );//Math.round( _read * _rate );(Изменено 16.09.2014)
							
							//Удаляем/Добавляем лишние данные
							_data.length = _pitcher.bytesLength;
							_pitcher.calculate( _target );
						}	
						else //Необходима обработка данных в несколько циклов
						{
							var i       : int = 0;
							var input   : ByteArray = new ByteArray();
							var output  : ByteArray = new ByteArray();
							var cLength : int;
							var pos     : Number;
							
							_target.position = 0;
							
							while( i < _read ) //Возможно тут вылетает ошибка
							{
								cLength = Math.min( _read - i, Calculation.MAX_DATA_WIDTH );
								
								pos    = _position + i / _rate;
								_alpha = pos - int( pos ); 
								
								input.position = 0;
								//trace( 'writeBytes1' );
								input.writeBytes( _data, AudioData.framesToBytes( i ), AudioData.framesToBytes( cLength ) );
								
								_pitcher.length = cLength;
								_pitcher.rate = _rate;
								_pitcher.alpha = _alpha;
								_pitcher.input = input;
								_pitcher.size =  Math.ceil( cLength * _rate );//Math.round( cLength * _rate );(Изменено 16.09.2014)
								
								_pitcher.calculate( output );
								
								_target.writeBytes( output, 0, AudioData.framesToBytes( _pitcher.size ) );
								
								i += cLength;
							}	
						}	
						
						buffer.position = AudioData.framesToBytes( Math.round( dstOffset ) );
						
						//trace( 'data', AudioData.bytesToFrames( buffer.position ), AudioData.bytesToFrames( _target.length ), length );
						
						buffer.writeBytes( _target, 0, AudioData.framesToBytes( length ) );
					}
					/*else
					{
					trace( 'Do do do' );
					}*/
				}	
			}
			
			//Boolean( params ) = true/false (invert)
			if ( params && Boolean( params ) )
			{
				_position = _orSrcOffset - _orLength;
				if( _position <= 0.0 ) _position = _length;
			}	
			else
			{
				_position = _orSrcOffset + _orLength;
				if ( _position >= _length ) _position = 0.0;
			}	
		}
		
		override public function clone() : IAudioData
		{
			var l : AudioLoop = new AudioLoop( original, _bpm, _loop );
			
			if ( _loop )
			{
				l.offset = _scaledOffset;
				l.length = _scaledLength;
			}
			else
			{
				l.offset = super.offset;
				l.length = super.length;
			}	
			
			l.inverted = inverted;
			
			return l;	
		}
		
		public function serializeToXML() : String
		{	
			var str : String = '';
			
			str += '<sample id="' + id + '">';
			str += '<loop>' + loop.toString() + '</loop>';
			str += '<inverted>' + inverted.toString() + '</inverted>';
			str += '<duration>' + length.toString() + '</duration>';
			str += '<offset>' + offset.toString() + '</offset>'; 
			str += '</sample>';
			
			return str;
		}
		
	}
}