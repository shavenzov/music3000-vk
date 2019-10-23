package com.audioengine.calculations
{
	import flash.display.Shader;
	import flash.utils.ByteArray;
	
	import pbjAS.PBJ;
	import pbjAS.PBJAssembler;
	import pbjAS.PBJChannel;
	import pbjAS.PBJParam;
	import pbjAS.PBJType;
	import pbjAS.ops.OpAdd;
	import pbjAS.ops.OpDiv;
	import pbjAS.ops.OpElse;
	import pbjAS.ops.OpEndIf;
	import pbjAS.ops.OpFloor;
	import pbjAS.ops.OpIf;
	import pbjAS.ops.OpLessThan;
	import pbjAS.ops.OpLoadFloat;
	import pbjAS.ops.OpMov;
	import pbjAS.ops.OpMul;
	import pbjAS.ops.OpSampleNearest;
	import pbjAS.ops.OpSub;
	import pbjAS.params.Parameter;
	import pbjAS.params.Texture;
	import pbjAS.regs.RFloat;
	import pbjAS.regs.RInt;

	public class PitchShift extends Calculation
	{
		/**
		 * Входные данные 
		 */		
		private var _input : ByteArray;
		
		/**
		 * На сколько сдвинуть частоту звука относительно оригинала 
		 */		
		private var _rate : Number = 1.0;
		
		/**
		 * Размер данных для обработки в исходном буфере в выборках
		 */		
		private var _size : Number;
		
		/**
		 * Коэффициент кореляции ( 0.0 .. 1.0 ) 
		 */		
		private var _alpha : Number;
		
		public function PitchShift(length:int=0)
		{
			super( length, 1);
		}
		
		public function get input() : ByteArray
		{
			return _input;
		}	
		
		public function set input( value : ByteArray ) : void
		{
			_input = value;
			_propertyChanged = true;
		}	
		
		public function get rate() : Number
		{
			return _rate;
		}
		
		public function set rate( value : Number ) : void
		{
			if ( _rate != value )
			{
				_rate = value;
				_propertyChanged = true;
			}	
		}
		
		public function get alpha() : Number
		{
			return _alpha;
		}
		
		public function set alpha( value : Number ) : void
		{
			if ( _alpha != value )
			{
				_alpha = value;
				_propertyChanged = true;
			}	
		}	
		
		public function get size() : Number
		{
			return _size;
		}
		
		public function set size( value : Number ) : void
		{
			if ( _size != value )
			{
				_size = value;
				_propertyChanged = true;
			}	
		}
		
		override protected function buildShader() : void
		{
			super.buildShader();
			
			var pbj : PBJ = createPBJ( 'pitchShiftingTask' );
			
			pbj.parameters.push( 
				//Входные данные (Индекс 0)
				new PBJParam( 'input', new Texture( 2, 0 ) )
			);
			
			pbj.parameters.push(
				//Сдвиг частоты звука( Регистр 2 )
				new PBJParam( 'rate', new Parameter( PBJType.TFloat2, false, new RFloat( 2, _channels ) ) ),
				//Коэффициент кореляции ( регистр 3 )
				new PBJParam( 'alpha', new Parameter( PBJType.TFloat2, false, new RFloat( 3, _channels ) ) ),
				//Размер обрабатываемых данных ( регистр 4 )
				new PBJParam( 'size', new Parameter( PBJType.TFloat2, false, new RFloat( 4, _channels ) ) )
			);
			
			pbj.code = [
				
		        new OpFloor( new RFloat( 6, _channels ), new RFloat( 0, _channels ) ), //v6 = outCoord;
		
				//Результат условия outCoord < size ( Регистр 6 )
				new OpLessThan( new RFloat( 6, [ PBJChannel.R ] ), new RFloat( 4, [ PBJChannel.R ] ) ), //i0 = outCoord < size( size );
				
				//new OpMov( new RFloat( 1, [ PBJChannel.R ] ), new RFloat( 0, [ PBJChannel.R ] ) ),
				//new OpMov( new RFloat( 1, [ PBJChannel.G ] ), new RFloat( 6, [ PBJChannel.R ] ) )
				
				new OpIf( new RInt( 0, [ PBJChannel.R ] ) ), //if ( posTargetNum < size )
				   
				  //Алгоритм
				  //_rate * floor( outCoord().r );
				  new OpDiv( new RFloat( 6, _channels ), new RFloat( 2, _channels ) ), //v6 /= rate;
				  //position (6)
				  new OpAdd( new RFloat( 6, [ PBJChannel.R ] ), new RFloat( 3, [ PBJChannel.R ] ) ), //v6[ R ] += alpha[ R ];
				  
				  //alpha (7)
				  new OpMov( new RFloat( 7, [ PBJChannel.R ] ), new RFloat( 6, [ PBJChannel.R ] ) ), //v7[ R ] = v6[ R ] 
				  new OpMov( new RFloat( 7, [ PBJChannel.G ] ), new RFloat( 6, [ PBJChannel.R ] ) ), //v7[ G ] = v6[ R ] 
				  new OpFloor( new RFloat( 8, _channels ), new RFloat( 7, _channels ) ), //v8 = floor( v7 );
				  new OpSub( new RFloat( 7, _channels ), new RFloat( 8, _channels ) ), //v7 -= v8;
				  
				  //Округление вниз position
				  new OpFloor( new RFloat( 6, _channels ), new RFloat( 6, _channels ) ),
				  
				  //Первая выборка (Регистр 8)
				  new OpSampleNearest( new RFloat( 8, _channels ), new RFloat( 6, _channels ), 0 ), //v8 = sampleNearest( v6 );    
				
				  //Вторая выборка (Регистр 9)
				  new OpMov( new RFloat( 9, _channels ), new RFloat( 6, _channels ) ), //v9 = v6;
				  new OpLoadFloat( new RFloat( 10, [ PBJChannel.R ] ), 1.0 ),                   //v10[ R ] = 0.5;
				  new OpAdd( new RFloat( 9, [ PBJChannel.R ] ), new RFloat( 10, [ PBJChannel.R ] ) ),  //v9[ R ] += v10[ R ];
				  new OpSampleNearest( new RFloat( 9, _channels ), new RFloat( 9, _channels ), 0 ), //v9 = sampleNearest( v9 );
				  
				  //Складываем
				  //l0 + alpha * ( l1 - l0 )
				  new OpMov( new RFloat( 10, _channels ), new RFloat( 9, _channels ) ), //v10 = v9;
				  new OpSub( new RFloat( 10, _channels ), new RFloat( 8, _channels ) ), //v10 -= v8;
				  new OpMul( new RFloat( 10, _channels ), new RFloat( 7, _channels ) ), //v10 *= v7(alpha);
				  new OpAdd( new RFloat( 10, _channels ), new RFloat( 8, _channels ) ), //v10 += v8;
				  
				  //Заносим в выходной массив
				  new OpMov( new RFloat( 1, _channels ), new RFloat( 10, _channels ) ),
				  //new OpMov( new RFloat( 1, [ PBJChannel.R ] ), new RFloat( 8, [ PBJChannel.R ] ) ),
				  //new OpMov( new RFloat( 1, [ PBJChannel.G ] ), new RFloat( 9, [ PBJChannel.R ] ) ),//v1 = v9;
				  
				new OpElse(),
				 new OpLoadFloat( new RFloat( 1, _channels ), 0.0 ),
				new OpEndIf()
				
				];
			
			//Добавляем выход
			addOutput( pbj, 1 );
			
			//Собираем Shader
			_shader = new Shader( PBJAssembler.assemble( pbj ) );
		}	
		
		override protected function propertyChanged() : void
		{
			super.propertyChanged();
			
			setData( 'input', _input );
			setValue( 'rate', [ _rate, _rate ] );
			setValue( 'alpha', [ _alpha, _alpha ] );
			setValue( 'size', [ _size, _height ] );
		}	
	}
}