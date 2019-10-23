package com.audioengine.automatization.easing
{
	import com.audioengine.calculations.ICalculation;

	public interface IEasing extends ICalculation
	{
		function get d():Number
		function set d(value:Number):void
		
		
		/**
		 * На сколько увеличится конечное значение от _b в самом конце 
		 */
		 function get c():Number
		 function set c(value:Number):void
		
		
		/**
		 * Начальное значение 
		 */
		function get b():Number
		
		
		/**
		 * @private
		 */
		function set b(value:Number):void
		
		
		/**
		 * Смещение текущей позиции 
		 */
		function get t():Number
		
		
		/**
		 * @private
		 */
		 function set t(value:Number):void
		
	}
}