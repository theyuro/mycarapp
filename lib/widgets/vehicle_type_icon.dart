import 'package:flutter/material.dart';

import '../models/vehicle.dart';

IconData vehicleTypeIcon(Vehicle vehicle) => vehicle.isMotorcycle
    ? Icons.two_wheeler_rounded
    : Icons.directions_car_rounded;
