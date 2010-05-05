/*  
 * The MIT License
 *
 * Copyright (c) 2008
 * United Nations Office at Geneva
 * Center for Advanced Visual Analytics
 * http://cava.unog.ch
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
package birdeye.vis.coords
{	
	import birdeye.vis.VisScene;
	import birdeye.vis.elements.geometry.TextElement;
	import birdeye.vis.guides.axis.Axis;
	import birdeye.vis.interfaces.*;
	import birdeye.vis.interfaces.coords.ICoordinates;
	import birdeye.vis.interfaces.elements.IElement;
	import birdeye.vis.interfaces.guides.IAxis;
	import birdeye.vis.interfaces.guides.IGuide;
	import birdeye.vis.interfaces.interactivity.IInteractivityManager;
	import birdeye.vis.interfaces.scales.IScale;
	import birdeye.vis.scales.*;
	
	import com.degrafa.Surface;
	import com.degrafa.geometry.RasterText;
	import com.degrafa.paint.SolidFill;
	
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.text.TextFieldAutoSize;
	
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.effects.DefaultListEffect;
	
	import org.greenthreads.IGuideThread;
	
	/** A CartesianChart can be used to create any 2D or 3D cartesian charts available in the library
	 * apart from those who might have specific features, like stackable element or data-sizable items.
	 * Those specific features are managed directly by charts that extends the CartesianChart 
	 * (AreaChart, BarChart, ColumnChart for stackable element and ScatterPlot, BubbleChart for 
	 * data-sizable items.
	 * The CartesianChart serves as container for all axes and element and coordinates the different
	 * data loading and creation of each component.
	 * If a CartesianChart is provided with an axis, this axis will be shared by all element that have 
	 * not that same axis (x, y or z). In the same way, the CartesianChart provides a dataProvider property 
	 * that can be shared with element that have not a dataProvider. In case the CartesianChart dataProvider 
	 * is used along with some element dataProvider, than the relevant values defined be the element fields
	 * of all these dataProviders will define the axes (min, max for NumericAxis elements 
	 * for CategorScale2, etc).
	 * 
	 * A CartesianChart may have multiple and different type of element, multiple axes and 
	 * multiple dataProvider(s).
	 * Most of available cartesian charts are also 3D. If a element specifies the zField, than the chart will
	 * be a 3D chart. By default zAxis is placed at the bottom right of the chart, for this reason it's
	 * recommended to place Scale2 to the left of the chart when using 3D charts.
	 * Given the current 3D limitations of the FP platform, for which is not possible to draw
	 * real 3D graphics (moveTo, drawRect, drawLine etc don't include the z coordinate), the AreaChart 
	 * and LineChart are not 3D yet. 
	 * */ 
	[Exclude(name="elementsContainer", kind="property")]
	public class Cartesian extends BaseCoordinates implements ICoordinates
	{
		
		private var _topLeftText:String;
		
		public function set topLeftText(s:String):void
		{
			_topLeftText = s;
		}
		
		public function get topLeftText():String
		{
			return _topLeftText;
		}
		
		
		private var _is3D:Boolean = false;
		public function get is3D():Boolean
		{
			return _is3D;
		}

		// UIComponent flow
		public function Cartesian()
		{
			super();				
			coordType = VisScene.CARTESIAN;
		}
		
		private var leftContainer:Container, rightContainer:Container;
		private var topContainer:Container, bottomContainer:Container;
		private var zContainer:Container;
		/** @Private
		 * Crete and add all containers that define the chart structure.
		 * The elementsContainer will contain all chart elements. Remove scrolling and clip the content 
		 * to true for each of them.*/ 
		override protected function createChildren():void
		{
			super.createChildren();
			
			addChild(leftContainer = new HBox());
			addChild(rightContainer = new HBox());
			addChild(topContainer = new VBox());
			addChild(bottomContainer = new VBox());
			addChild(zContainer = new HBox());
			addChild(_elementsContainer);
						
			zContainer.verticalScrollPolicy = "off";
			zContainer.clipContent = false;
			zContainer.horizontalScrollPolicy = "off";
			zContainer.setStyle("horizontalAlign", "left");
			
			leftContainer.verticalScrollPolicy = "off";
			leftContainer.clipContent = false;
			leftContainer.horizontalScrollPolicy = "off";
			leftContainer.setStyle("horizontalAlign", "right");
			leftContainer.setStyle("horizontalGap", 0);
			leftContainer.setStyle("verticalGap", 0);

			rightContainer.verticalScrollPolicy = "off";
			rightContainer.clipContent = false;
			rightContainer.horizontalScrollPolicy = "off";
			rightContainer.setStyle("horizontalAlign", "left");
			rightContainer.setStyle("horizontalGap", 0);
			rightContainer.setStyle("verticalGap", 0);

			topContainer.verticalScrollPolicy = "off";
			topContainer.clipContent = false;
			topContainer.horizontalScrollPolicy = "off";
			topContainer.setStyle("verticalAlign", "bottom");
			topContainer.setStyle("horizontalGap", 0);
			topContainer.setStyle("verticalGap", 0);

			bottomContainer.verticalScrollPolicy = "off";
			bottomContainer.clipContent = false;
			bottomContainer.horizontalScrollPolicy = "off";
			bottomContainer.setStyle("horizontalGap", 0);
			bottomContainer.setStyle("verticalGap", 0);
			
		}
		
		override protected function placeGuide(guide:IGuide):void
		{
			if (guide.position == "sides")
			{
				if (guide is IAxis)
				{
					var axis:IAxis = guide as IAxis;
					switch (axis.placement)
					{
						case Axis.TOP:
							if(axis is DisplayObject && !topContainer.contains(DisplayObject(axis)))
							{
								topContainer.addChild(DisplayObject(axis));
							}
							break; 
						case Axis.BOTTOM:
							if(axis is DisplayObject && !bottomContainer.contains(DisplayObject(axis)))
							{
								bottomContainer.addChild(DisplayObject(axis));
							}
							break;
							
						case Axis.LEFT:
							if(axis is DisplayObject && !leftContainer.contains(DisplayObject(axis)))
							{
								leftContainer.addChild(DisplayObject(axis));
							}
							break;
						case Axis.RIGHT:
							if(axis is DisplayObject && !rightContainer.contains(DisplayObject(axis)))
							{
								rightContainer.addChild(DisplayObject(axis));
							}
							break;
					}
				}
			}
			else if (guide.position == "elements")
			{
				if (guide is DisplayObject)
				{
				
					if (!elementsContainer.contains(DisplayObject(guide)))
					{
						if (!DisplayObject(guide).parent)
						{
							elementsContainer.addChild(DisplayObject(guide));
						}
					}
				}	
			}
		}
		
		override protected function initElement(element:IElement, countStackableElements:Array):uint
		{
			var nCursors:uint = super.initElement(element, countStackableElements);
 			
 			return nCursors;
				
		}
			
		// other methods
		protected var top:Number = 0, left:Number = 0, right:Number = 0, bottom:Number=0;
		
	
		override protected function setBounds(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if (maximumElementCanvasSize)
			{
				var topAndBottom:Number = unscaledHeight - maximumElementCanvasSize.height;	
				var leftAndRight:Number = unscaledWidth - maximumElementCanvasSize.width;
				
				if (topAndBottom > 0)
				{
					bottom = top = (unscaledHeight - maximumElementCanvasSize.height - topContainer.height - bottomContainer.height) / 2;
				}
				
				if (leftAndRight > 0)
				{
					left = right = (unscaledWidth - maximumElementCanvasSize.width - leftContainer.width - rightContainer.width) / 2;
				}
			}
			
			if (_topLeftText != null && _topLeftText != "")
			{
				if (left == 0)
				{
					left = 30;
				}
			}
			
			leftContainer.move(left, top + topContainer.height);
			topContainer.move(left + leftContainer.width, top);
			bottomContainer.move(left + leftContainer.width, (unscaledHeight - bottomContainer.height - bottom));
			rightContainer.move(unscaledWidth - rightContainer.width - left, top + topContainer.height);

			chartBounds = new Rectangle(leftContainer.x + leftContainer.width, 
										topContainer.y + topContainer.height,
										unscaledWidth - (leftContainer.width + rightContainer.width + left + right),
										unscaledHeight - (topContainer.height + bottomContainer.height + top + bottom));
										
			topContainer.width = bottomContainer.width = chartBounds.width;

			leftContainer.setActualSize(leftContainer.width, chartBounds.height);
			rightContainer.setActualSize(rightContainer.width, chartBounds.height);			
			
			// the z container is placed at the right of the chart
  			zContainer.move(int(chartBounds.width + leftContainer.width), int(chartBounds.height));
				
			if (axesFeeded && 
				(_elementsContainer.x != chartBounds.x ||
				_elementsContainer.y != chartBounds.y ||
				_elementsContainer.width != chartBounds.width ||
				_elementsContainer.height != chartBounds.height))
			{
				_elementsContainer.move(chartBounds.x, chartBounds.y);
				_elementsContainer.setActualSize(chartBounds.width, chartBounds.height);
 	
				if (_is3D)
					rotationY = 42;
				else
					transform.matrix3D = null;
 			}
			
			
			this.graphics.clear();
			
			if (_topLeftText != null && _topLeftText != "")
			{
				defaultLabel.fontFamily = "DIN Medium";
				defaultLabel.fill = new SolidFill(0x505760);
				defaultLabel.fontSize = 10;
				defaultLabel.autoSize = TextFieldAutoSize.LEFT;
				defaultLabel.autoSizeField = true;
				defaultLabel.text = _topLeftText;
				defaultLabel.y = top + topContainer.height - defaultLabel.displayObject.height /2 - 22;
				defaultLabel.x = left + leftContainer.width - defaultLabel.textWidth  - 22;
	
				defaultLabel.draw(this.graphics, null);
			}
			
		}
		
		override protected function updateElement(element:IElement, unscaledWidth:Number, unscaledHeight:Number):void
		{
			Surface(element).width = chartBounds.width;
			Surface(element).height = chartBounds.height;
			
			var scale1:IScale = element.scale1;
			var scale2:IScale = element.scale2;
			
			if (scale1)
			{
				scale1.size = chartBounds.width;
			}
			
			if (scale2)
			{
				scale2.size = chartBounds.height;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateGuide(guide:IGuide, unscaledWidth:Number, unscaledHeight:Number):void
		{
			if (guide is IAxis)
			{
				var axis:IAxis = guide as IAxis;
			
				switch (axis.placement)
				{
					case Axis.BOTTOM:
						axis.size = chartBounds.width;
						break;
					case Axis.TOP:
						axis.size = chartBounds.width;
						break;
					case Axis.LEFT:
						axis.size = chartBounds.height;
						break;
					case Axis.RIGHT:
						axis.size = chartBounds.height;
				}
			}
			
		}
		
		private var defaultLabel:RasterText = new RasterText();
		
		override protected function drawGuides(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.drawGuides(unscaledWidth, unscaledHeight);

		}
		
		override protected function drawGuide(guide:IGuideThread, unscaledWidth:Number, unscaledHeight:Number):void
		{
			if (guide is IAxis)
			{
				var axis:IAxis = guide as IAxis;
			
				switch (axis.placement)
				{
					case Axis.BOTTOM:
						addGuideToThreads(guide, new Rectangle(0,0, bottomContainer.width , axis.minHeight));
						break;
					case Axis.TOP:
						addGuideToThreads(guide, new Rectangle(0,0, topContainer.width, axis.minHeight));
						break;
					case Axis.LEFT:
						addGuideToThreads(guide, new Rectangle(0,0, axis.minWidth, leftContainer.height));
						break;
					case Axis.RIGHT:
						addGuideToThreads(guide,new Rectangle(0,0, axis.minWidth, rightContainer.height));
				}
							
			}
			else
			{
				addGuideToThreads(guide,chartBounds);
			}
		}

		
		private var leftSize:Number = 0, oldLeftSize:Number = 0;
		private var rightSize:Number = 0, oldRightSize:Number = 0;
		private var topSize:Number = 0, oldTopSize:Number = 0;
		private var bottomSize:Number = 0, oldBottomSize:Number = 0;

		/** @Private
		 * Validate border containers sizes, that depend on the axes sizes that they contain.*/
		override protected function validateBounds(unscaledWidth:Number, unscaledHeight:Number):Boolean
		{
			// validate bounds logic has changed as axes are not always added to containers
			// they can draw to containers, without being added to them
			// so this logic is reformed to loop axes and not containers containing them

			oldLeftSize = leftSize;
			oldBottomSize = bottomSize;
			oldTopSize = topSize;
			oldRightSize = rightSize;
			
			leftSize = 0;
			rightSize = 0;
			bottomSize = 0;
			topSize = 0;
						
			for each (var guide:IGuide in guides)
			{
				if (guide is IAxis)
				{
					var axis:IAxis = guide as IAxis;
										
					switch (axis.placement)
					{
						case Axis.BOTTOM:
							bottomSize += axis.minHeight;
							break;
						case Axis.TOP:
							topSize += axis.minHeight;
							break;
						case Axis.RIGHT:
							rightSize += axis.minWidth;
							break;
						case Axis.LEFT:
							leftSize += axis.minWidth;
							break;
					}
				}
			}
			
			
			
			
			var invalidated:Boolean = false;
			
			if (leftSize != oldLeftSize)
			{
				leftContainer.width = leftSize;
				
				invalidateAxis(Axis.LEFT);
				
				invalidated = true;
			}
			
			if (rightSize != oldRightSize)
			{
				rightContainer.width = rightSize;
				
				invalidateAxis(Axis.RIGHT);
				
				invalidated = true;
			}
			
			if (topSize != oldTopSize)
			{
				topContainer.height = topSize;				
				
				invalidateAxis(Axis.TOP);
				
				invalidated = true;
			}
			
			if (bottomSize != oldBottomSize)
			{
				bottomContainer.height = bottomSize;
				
				invalidateAxis(Axis.BOTTOM);
				
				invalidated = true;
			}
			
			if (invalidated)
			{
				// if one of the axis changes size, the elements also change size...
				invalidateElement();
			}
			

			
			return super.validateBounds(unscaledWidth, unscaledHeight) || invalidated;
		}
		
		
		public function invalidateAxis(axisPlace:String):void
		{
			for each (var guide:IGuide in guides)
			{
				if (guide is IAxis)
				{
					if ((guide as IAxis).placement == axisPlace)
					{
						invalidateGuide(guide);
					}
				}
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function removeAllElements():void
		{
			super.removeAllElements();
			var i:int; 
			var child:*;
			
			if (leftContainer)
			{
				for (i = 0; i<leftContainer.numChildren; i++)
				{
					child = leftContainer.getChildAt(0); 
					if (child is IAxis)
						IAxis(child).clearAll();
				}
				leftContainer.removeAllChildren();
			}

			if (rightContainer)
			{
				for (i = 0; i<rightContainer.numChildren; i++)
				{
					child = rightContainer.getChildAt(0); 
					if (child is IAxis)
						IAxis(child).clearAll();
				}
				rightContainer.removeAllChildren();
			}
			
			if (topContainer)
			{
				for (i = 0; i<topContainer.numChildren; i++)
				{
					child = topContainer.getChildAt(0); 
					if (child is IAxis)
						IAxis(child).clearAll();
				}
				topContainer.removeAllChildren();
			}

			if (bottomContainer)
			{
				for (i = 0; i<bottomContainer.numChildren; i++)
				{
					child = bottomContainer.getChildAt(0); 
					if (child is IAxis)
						IAxis(child).clearAll();
				}
				bottomContainer.removeAllChildren();
			}

			if (bottomContainer)
			{
				for (i = 0; i<bottomContainer.numChildren; i++)
				{
					child = bottomContainer.getChildAt(0); 
					if (child is IAxis)
						IAxis(child).clearAll();
				}
				bottomContainer.removeAllChildren();
			}

		}
	}
}