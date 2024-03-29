//
//  NavigationBar.swift
//  Tangem Tap
//
//  Created by Andrew Son on 21/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct ArrowBack: View {
	let action: () -> Void
	let height: CGFloat
	var color: Color = .tangemTapGrayDark6
	
	var body: some View {
		Button(action: action, label: {
			Image(systemName: "chevron.left")
				.frame(width: height, height: height)
				.font(.system(size: 20, weight: .medium))
				.foregroundColor(color)
		})
		.frame(width: height, height: height)
	}
}



struct NavigationBar<LeftButtons: View, RightButtons: View>: View {
	
	struct Settings {
		let titleFont: Font
		let titleColor: Color
		let backgroundColor: Color
		let horizontalPadding: CGFloat
		let height: CGFloat
		
		init(titleFont: Font = .system(size: 17, weight: .medium),
			 titleColor: Color = .tangemTapGrayDark6,
			 backgroundColor: Color = .tangemTapBgGray,
			 horizontalPadding: CGFloat = 0,
			 height: CGFloat = 44) {
			
			self.titleFont = titleFont
			self.titleColor = titleColor
			self.backgroundColor = backgroundColor
			self.horizontalPadding = horizontalPadding
			self.height = height
		}
		
//		static var `default`: Settings { .init() }
		
	}
	
	private let title: LocalizedStringKey
	private let settings: Settings
	private let leftButtons: LeftButtons
	private let rightButtons: RightButtons
	
	init(
		title: LocalizedStringKey,
		settings: Settings = .init(),
		@ViewBuilder leftItems: () -> LeftButtons,
		@ViewBuilder rightItems: () -> RightButtons
	) {
		self.title = title
		self.settings = settings
		leftButtons = leftItems()
		rightButtons = rightItems()
	}
	
	var body: some View {
		ZStack {
			HStack {
				leftButtons
				Spacer()
				rightButtons
			}
			Text(title)
				.font(settings.titleFont)
				.foregroundColor(settings.titleColor)
		}
		.padding(.horizontal, settings.horizontalPadding)
		.frame(height: settings.height)
		.background(settings.backgroundColor.edgesIgnoringSafeArea(.all))
	}
}

extension NavigationBar where LeftButtons == EmptyView {
	init(
		title: LocalizedStringKey,
		settings: Settings = .init(),
		@ViewBuilder rightButtons: () -> RightButtons
	) {
		leftButtons = EmptyView()
		self.rightButtons = rightButtons()
		self.title = title
		self.settings = settings
	}
}

extension NavigationBar where RightButtons == EmptyView {
    init(
        title: LocalizedStringKey,
        settings: Settings = .init(),
        @ViewBuilder leftButtons: () -> LeftButtons
    ) {
        rightButtons = EmptyView()
        self.leftButtons = leftButtons()
        self.title = title
        self.settings = settings
    }
}

extension NavigationBar where LeftButtons == ArrowBack, RightButtons == EmptyView {
	init(
		title: LocalizedStringKey,
		settings: Settings = .init(),
		backAction: @escaping () -> Void
	) {
		leftButtons = ArrowBack(action: {
			backAction()
		}, height: settings.height)
		rightButtons = EmptyView()
		self.title = title
		self.settings = settings
	}
}

extension NavigationBar where LeftButtons == ArrowBack, RightButtons == EmptyView {
	init(
		title: LocalizedStringKey,
		settings: Settings = .init(),
		presentationMode:  Binding<PresentationMode>
	) {
		leftButtons = ArrowBack(action: {
			presentationMode.wrappedValue.dismiss()
		}, height: settings.height)
		rightButtons = EmptyView()
		self.title = title
		self.settings = settings
	}
}

struct NavigationBar_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			VStack {
				NavigationBar(title: "Hello, World!", backAction: {})
				Spacer()
			}.deviceForPreview(.iPhone11Pro)
			VStack {
				NavigationBar(title: "Hello, World!", rightButtons: {
					Button(action: {},
						   label: {
							Image("verticalDots")
								.foregroundColor(Color.tangemTapGrayDark6)
								.frame(width: 44.0, height: 44.0, alignment: .center)
						   })
				})
				Spacer()
			}.deviceForPreview(.iPhone11ProMax)
		}
	}
}

