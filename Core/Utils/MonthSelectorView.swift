import SwiftUI

struct MonthOption: Identifiable, Equatable {
    let id = UUID()
    let date: Date?    // nil = All Time
    let label: String
}

struct MonthSelectorView: View {
    @Binding var selectedOption: MonthOption
    let options: [MonthOption]
    
    var body: some View {
        Menu {
            ForEach(options) { option in
                Button(option.label) {
                    selectedOption = option
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedOption.label)
                    .font(.subheadline.bold())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(AppTheme.primaryIndigo)
        }
    }
    
    // MARK: - Dynamic Options based on user's actual transaction history
    // Sirf tab tak ke months dikhata hai jab se user ka pehla transaction bana hai
    static func generateOptions(from transactions: [Transaction]) -> [MonthOption] {
        var options: [MonthOption] = [MonthOption(date: nil, label: "All Time")]
        
        guard let earliestDate = transactions.map({ $0.date }).min() else {
            // Koi transaction nahi hai abhi tak - sirf current month dikhao
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            options.append(MonthOption(date: Date(), label: formatter.string(from: Date())))
            return options
        }
        
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let now = Date()
        var monthDate = now
        
        // Aaj se lekar earliest transaction ke month tak, ek-ek karke months add karo
        while monthDate >= calendar.dateInterval(of: .month, for: earliestDate)?.start ?? earliestDate {
            options.append(MonthOption(date: monthDate, label: formatter.string(from: monthDate)))
            guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: monthDate) else { break }
            monthDate = previousMonth
        }
        
        return options
    }
    
    // Fallback jab transactions abhi load nahi hui hon (initial state ke liye)
    static var currentMonthOption: MonthOption {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return MonthOption(date: Date(), label: formatter.string(from: Date()))
    }
}
