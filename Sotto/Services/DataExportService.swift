import Foundation
import SwiftData

// MARK: - ExportPayload

struct ExportPayload: Codable {
    static let currentVersion = 1

    let version: Int
    let exportedAt: Date
    let categories: [CategoryDTO]
    let paymentMethods: [PaymentMethodDTO]
    let subscriptions: [SubscriptionDTO]
    let paymentHistory: [PaymentHistoryDTO]
}

// MARK: - DTOs

struct CategoryDTO: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let icon: String
}

struct PaymentMethodDTO: Codable {
    let id: UUID
    let name: String
    let type: String
}

struct SubscriptionDTO: Codable {
    let id: UUID
    let name: String
    let icon: String
    let amount: Decimal
    let currencyCode: String
    let billingCycle: String
    let startDate: Date
    let nextDueDate: Date
    let categoryID: UUID?
    let paymentMethodID: UUID?
    let status: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct PaymentHistoryDTO: Codable {
    let id: UUID
    let subscriptionID: UUID?
    let paidDate: Date
    let amount: Decimal
    let currencyCode: String
}

// MARK: - Service

enum DataExportService {

    enum ImportMode {
        case replace
        case merge
    }

    enum ExportError: LocalizedError {
        case fetchFailed(Error)
        case encodeFailed(Error)
        case decodeFailed(Error)
        case versionUnsupported(Int)

        var errorDescription: String? {
            switch self {
            case .fetchFailed(let e): return "Could not read data: \(e.localizedDescription)"
            case .encodeFailed(let e): return "Could not encode backup: \(e.localizedDescription)"
            case .decodeFailed(let e): return "Could not read backup file: \(e.localizedDescription)"
            case .versionUnsupported(let v): return "Backup format version \(v) is not supported."
            }
        }
    }

    // MARK: Encode

    static func encodedSnapshot(from context: ModelContext) throws -> Data {
        let payload = try snapshot(from: context)
        return try encode(payload)
    }

    static func snapshot(from context: ModelContext) throws -> ExportPayload {
        do {
            let cats = try context.fetch(FetchDescriptor<Category>())
            let pms = try context.fetch(FetchDescriptor<PaymentMethod>())
            let subs = try context.fetch(FetchDescriptor<Subscription>())
            let hist = try context.fetch(FetchDescriptor<PaymentHistory>())

            return ExportPayload(
                version: ExportPayload.currentVersion,
                exportedAt: .now,
                categories: cats.map { CategoryDTO(id: $0.id, name: $0.name, colorHex: $0.colorHex, icon: $0.icon) },
                paymentMethods: pms.map { PaymentMethodDTO(id: $0.id, name: $0.name, type: $0.type.rawValue) },
                subscriptions: subs.map { sub in
                    SubscriptionDTO(
                        id: sub.id,
                        name: sub.name,
                        icon: sub.icon,
                        amount: sub.amount,
                        currencyCode: sub.currencyCode,
                        billingCycle: sub.billingCycle.rawValue,
                        startDate: sub.startDate,
                        nextDueDate: sub.nextDueDate,
                        categoryID: sub.category?.id,
                        paymentMethodID: sub.paymentMethod?.id,
                        status: sub.status.rawValue,
                        notes: sub.notes,
                        createdAt: sub.createdAt,
                        updatedAt: sub.updatedAt
                    )
                },
                paymentHistory: hist.map {
                    PaymentHistoryDTO(
                        id: $0.id,
                        subscriptionID: $0.subscription?.id,
                        paidDate: $0.paidDate,
                        amount: $0.amount,
                        currencyCode: $0.currencyCode
                    )
                }
            )
        } catch {
            throw ExportError.fetchFailed(error)
        }
    }

    static func encode(_ payload: ExportPayload) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(payload)
        } catch {
            throw ExportError.encodeFailed(error)
        }
    }

    // MARK: Decode

    static func decode(_ data: Data) throws -> ExportPayload {
        let payload: ExportPayload
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            payload = try decoder.decode(ExportPayload.self, from: data)
        } catch {
            throw ExportError.decodeFailed(error)
        }
        guard payload.version <= ExportPayload.currentVersion else {
            throw ExportError.versionUnsupported(payload.version)
        }
        return payload
    }

    // MARK: Restore

    static func restore(_ payload: ExportPayload, into context: ModelContext, mode: ImportMode) throws {
        if mode == .replace {
            try context.delete(model: PaymentHistory.self)
            try context.delete(model: Subscription.self)
            try context.delete(model: Category.self)
            try context.delete(model: PaymentMethod.self)
        }

        var catByID: [UUID: Category] = [:]
        var pmByID: [UUID: PaymentMethod] = [:]
        var subByID: [UUID: Subscription] = [:]

        for c in try context.fetch(FetchDescriptor<Category>()) { catByID[c.id] = c }
        for p in try context.fetch(FetchDescriptor<PaymentMethod>()) { pmByID[p.id] = p }
        for s in try context.fetch(FetchDescriptor<Subscription>()) { subByID[s.id] = s }
        let existingHistoryIDs = Set(try context.fetch(FetchDescriptor<PaymentHistory>()).map(\.id))

        for dto in payload.categories {
            if mode == .merge, catByID[dto.id] != nil { continue }
            let model = Category(name: dto.name, colorHex: dto.colorHex, icon: dto.icon)
            model.id = dto.id
            context.insert(model)
            catByID[dto.id] = model
        }

        for dto in payload.paymentMethods {
            if mode == .merge, pmByID[dto.id] != nil { continue }
            let type = PaymentMethodType(rawValue: dto.type) ?? .other
            let model = PaymentMethod(name: dto.name, type: type)
            model.id = dto.id
            context.insert(model)
            pmByID[dto.id] = model
        }

        for dto in payload.subscriptions {
            if mode == .merge, subByID[dto.id] != nil { continue }
            let cycle = BillingCycle(rawValue: dto.billingCycle) ?? .monthly
            let status = SubscriptionStatus(rawValue: dto.status) ?? .active
            let model = Subscription(
                name: dto.name,
                icon: dto.icon,
                amount: dto.amount,
                currencyCode: dto.currencyCode,
                billingCycle: cycle,
                startDate: dto.startDate,
                nextDueDate: dto.nextDueDate,
                category: dto.categoryID.flatMap { catByID[$0] },
                paymentMethod: dto.paymentMethodID.flatMap { pmByID[$0] },
                status: status,
                notes: dto.notes
            )
            model.id = dto.id
            model.createdAt = dto.createdAt
            model.updatedAt = dto.updatedAt
            context.insert(model)
            subByID[dto.id] = model
        }

        for dto in payload.paymentHistory {
            if mode == .merge, existingHistoryIDs.contains(dto.id) { continue }
            guard let subID = dto.subscriptionID, let sub = subByID[subID] else { continue }
            let model = PaymentHistory(
                subscription: sub,
                paidDate: dto.paidDate,
                amount: dto.amount,
                currencyCode: dto.currencyCode
            )
            model.id = dto.id
            context.insert(model)
        }

        try context.save()
    }
}
