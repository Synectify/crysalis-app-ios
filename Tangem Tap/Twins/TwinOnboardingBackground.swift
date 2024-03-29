//
//  TwinOnboardingBackground.swift
//  Tangem Tap
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct TwinOnboardingBackground: View {
	
	struct ColoredLine: Identifiable {
		let id = UUID()
		let color: Color
		let height: CGFloat
		let offset: CGFloat
	}
	
	enum ColorSet {
		case gray, orange
		
		var lines: [ColoredLine] {
			zip(zip(colors, heights), offset).map {
				ColoredLine(color: $0.0.0, height: $0.0.1, offset: $0.1)
			}
		}
		
		var heights: [CGFloat] {
			[192, 81, 107, 72]
		}
		
		var offset: [CGFloat] {
			[0, 0, -3.5, -7]
		}
		
		var colors: [Color] {
			switch self {
			case .gray: return [Color.tangemTapGrayDark6.opacity(0.22),
								Color.tangemTapGrayDark4.opacity(0.2),
								Color.tangemTapGrayDark2.opacity(0.2),
								Color.tangemTapGrayLight5.opacity(0.35)]
			case .orange: return [Color.tangemTapWarning.opacity(0.55),
								  Color.tangemTapWarning.opacity(0.45),
								  Color.tangemTapWarning.opacity(0.35),
								  Color.tangemTapWarning.opacity(0.25)]
			}
		}
	}
	
	var colorSet: ColorSet = .orange
	
    var body: some View {
		ZStack(alignment: .top) {
			VStack(spacing: 10.7) {
				ForEach(colorSet.lines) { line in
					line.color
						.frame(width: 550, height: line.height)
						.rotationEffect(.degrees(-22))
						.offset(y: line.offset)
				}
			}
			.offset(y: -64)
			.edgesIgnoringSafeArea(.all)
		}
        
    }
}

struct TwinOnboardingBackground_Previews: PreviewProvider {
    static var previews: some View {
        TwinOnboardingBackground()
			.deviceForPreview(.iPhone11ProMax)
    }
}
