package com.audioengine.automatization.easing
{
	import com.audioengine.calculations.Calculation;
	
	import pbjAS.PBJ;
	import pbjAS.PBJChannel;
	import pbjAS.PBJParam;
	import pbjAS.PBJType;
	import pbjAS.ops.OpAdd;
	import pbjAS.ops.OpFloor;
	import pbjAS.ops.OpMul;
	import pbjAS.params.Parameter;
	import pbjAS.regs.RFloat;
	
	public class EasingCalculation extends Calculation implements IEasing
	{
		protected const R : Array = [ PBJChannel.R ];
		protected const G : Array = [ PBJChannel.G ];
		
		protected var _t : Number;
		protected var _b : Number;
		protected var _c : Number;
		protected var _d : Number;
		
		public function EasingCalculation(length:int=0, height:int=-1)
		{
			super(length, height);
		}
		
		/**
		 * Длительность по времени в сэмплах 
		 */
		public function get d():Number
		{
			return _d;
		}
		
		/**
		 * @private
		 */
		public function set d(value:Number):void
		{
			_d = value;
			_propertyChanged = true;
		}
		
		/**
		 * На сколько увеличится конечное значение от _b в самом конце 
		 */
		public function get c():Number
		{
			return _c;
		}
		
		/**
		 * @private
		 */
		public function set c(value:Number):void
		{
			_c = value;
			_propertyChanged = true;
		}
		
		/**
		 * Начальное значение 
		 */
		public function get b():Number
		{
			return _b;
		}
		
		/**
		 * @private
		 */
		public function set b(value:Number):void
		{
			_b = value;
			_propertyChanged = true;
		}
		
		/**
		 * Смещение текущей позиции 
		 */
		public function get t():Number
		{
			return _t;
		}
		
		/**
		 * @private
		 */
		public function set t(value:Number):void
		{
			_t = value;
			_propertyChanged = true;
		}
		
		protected function createEasingPBJ( name : String ) : PBJ
		{
			var pbj : PBJ = createPBJ( name );
			
			pbj.parameters.push(
				//width( Регистр 2 )
				new PBJParam( 'width', new Parameter( PBJType.TFloat, false, new RFloat( 2, R) ) ),
				//t ( регистр 3 )
				new PBJParam( 't', new Parameter( PBJType.TFloat, false, new RFloat( 3, R ) ) ),
				//b ( регистр 4 )
				new PBJParam( 'b', new Parameter( PBJType.TFloat, false, new RFloat( 4, R ) ) ),
				//c ( регистр 5 )
				new PBJParam( 'c', new Parameter( PBJType.TFloat, false, new RFloat( 5, R ) ) ),
				//d ( регистр 6 )
				new PBJParam( 'd', new Parameter( PBJType.TFloat, false, new RFloat( 6, R ) ) )
			);
			
			pbj.code = [
				
				/*
				Вычисляем индекс
				*/
				
				//x ( 7 )
				new OpFloor( new RFloat( 10, R ), new RFloat( 0, R ) ),
				//y ( 8 )
				new OpFloor( new RFloat( 11, R ), new RFloat( 0, G ) ),
				
				//index (8) = _outCoords.y * width + _outCoords.x;  
				new OpMul( new RFloat( 11, R ), new RFloat( 2, R ) ), //mul width * _outCoords.y
				new OpAdd( new RFloat( 11, R ), new RFloat( 10, R ) ),    //add _outCoords.x
				
				/*
				добавляем смещение t
				*/
				new OpAdd( new RFloat( 11, R ), new RFloat( 3, R ) ), //t + index
				
				
			];
			
			//Добавляем выход
			pbj.parameters.push( new PBJParam( 'output', new Parameter( PBJType.TFloat, true, new RFloat( 1, R  ) ) ) );
			
			return pbj;
		}
		
		override protected function propertyChanged() : void
		{
			super.propertyChanged();
			
			setValue( 'width', [ _length / _height ] );
			setValue( 't', [ _t ] );
			setValue( 'b', [ _b ] );
			setValue( 'c', [ _c ] );
			setValue( 'd', [ _d ] );
		}
	}
}