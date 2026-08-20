//
//  MockCLVisit.swift
//  nearby
//
//  Created by Max Myron on 5/2/26.
//

import CoreLocation

class MockCLVisit: CLVisit {
    private let _coordinate: CLLocationCoordinate2D
    private let _arrivalDate: Date
    private let _departureDate: Date
    
    init(
        coordinate: CLLocationCoordinate2D,
        arrivalDate: Date,
        departureDate: Date = .distantFuture
    ) {
        _coordinate = coordinate
        _arrivalDate = arrivalDate
        _departureDate = departureDate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var coordinate: CLLocationCoordinate2D {
        return _coordinate
    }
    
    override var arrivalDate: Date {
        return _arrivalDate
    }
    
    override var departureDate: Date {
        return _departureDate
    }
}
