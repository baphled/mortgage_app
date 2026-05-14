# Mortgage Application API

A Ruby on Rails JSON API for managing mortgage applications and performing affordability assessments.

## Overview

This service provides a backend API for managing mortgage applications with three main endpoints:

1. **Create a mortgage application** - Submit application details for evaluation
2. **Retrieve an existing application** - Get application details by ID
3. **Perform affordability assessment** - Evaluate application against lending criteria

The API follows RESTful conventions and returns JSON responses for all endpoints.

## Setup Instructions

### Prerequisites

- Ruby 3.4.4 or higher
- PostgreSQL 12 or higher
- Bundler

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mortgage_app
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up the database**
   ```bash
   # Create the database
   rails db:create
   
   # Run migrations
   rails db:migrate
   ```

4. **Set up environment variables (optional)**
   ```bash
   cp .env.example .env
   # Edit .env with your database configuration if needed
   ```

### Running the Application

1. **Start the Rails server**
   ```bash
   rails server
   ```
   
   The API will be available at `http://localhost:3000`

2. **Or run with Puma in production mode**
   ```bash
   rails s -e production
   ```

### Running Tests

1. **Run all tests**
   ```bash
   bundle exec rspec
   ```

2. **Run specific test types**
   ```bash
   # Run model tests only
   bundle exec rspec spec/models
   
   # Run API request tests only
   bundle exec rspec spec/requests/api
   
   # Run service tests only
   bundle exec rspec spec/services
   ```

3. **Run tests with coverage**
   ```bash
   COVERAGE=true bundle exec rspec
   ```

## API Endpoints

### Create Mortgage Application

**POST** `/api/v1/mortgage_applications`

Creates a new mortgage application with the provided parameters.

**Request Body:**
```json
{
  "mortgage_application": {
    "annual_income": 75000,
    "monthly_expenses": 2000,
    "deposit_amount": 60000,
    "property_value": 300000,
    "term_years": 25
  }
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "annual_income": "75000.0",
  "monthly_expenses": "2000.0",
  "deposit_amount": "60000.0",
  "property_value": "300000.0",
  "term": 25,
  "created_at": "2026-05-14T10:30:00.000Z",
  "updated_at": "2026-05-14T10:30:00.000Z"
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "error": "Validation failed",
  "details": [
    "Annual income must be greater than 0",
    "Property value must be greater than 0"
  ]
}
```

### Retrieve Mortgage Application

**GET** `/api/v1/mortgage_applications/:id`

Retrieves an existing mortgage application by ID.

**Response (200 OK):**
```json
{
  "id": 1,
  "annual_income": "75000.0",
  "monthly_expenses": "2000.0",
  "deposit_amount": "60000.0",
  "property_value": "300000.0",
  "term": 25,
  "created_at": "2026-05-14T10:30:00.000Z",
  "updated_at": "2026-05-14T10:30:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "Mortgage application not found"
}
```

### Perform Affordability Assessment

**POST** `/api/v1/mortgage_applications/:id/affordability_assessment`

Performs an affordability assessment for an existing mortgage application.

**Response (201 Created):**
```json
{
  "id": 1,
  "mortgage_application_id": 1,
  "loan_to_value": "80.0",
  "debt_to_income_ratio": "32.0",
  "decision": "approved",
  "max_borrowing_estimate": "656250.0",
  "explanation": "Application meets all affordability criteria: LTV 80.0% (≤80%), debt-to-income 32.0% (≤40%), and sufficient deposit.",
  "created_at": "2026-05-14T10:30:00.000Z",
  "updated_at": "2026-05-14T10:30:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "Mortgage application not found"
}
```

## Affordability Assessment Logic

The affordability assessment evaluates applications based on three criteria:

### 1. Loan-to-Value (LTV) Ratio
- **Calculation:** `(Property Value - Deposit) / Property Value × 100`
- **Maximum allowed:** 80%
- **Purpose:** Ensures borrower has sufficient equity in the property

### 2. Debt-to-Income (DTI) Ratio
- **Calculation:** `(Monthly Expenses × 12) / Annual Income × 100`
- **Maximum allowed:** 40%
- **Purpose:** Ensures borrower can afford monthly payments

### 3. Minimum Deposit
- **Calculation:** Deposit must be at least 10% of property value
- **Purpose:** Reduces lender risk and ensures borrower commitment

### Decision Logic
An application is **approved** only if all three criteria are met. Otherwise, it is **declined** with an explanation of which criteria failed.

### Maximum Borrowing Estimate
- **Calculation:** `(Annual Income / 12) × 0.35 × (Term × 12)`
- **Assumption:** 35% of monthly income can be used for mortgage payments over the term

## Design & Reflection

### Key Design Decisions

#### 1. Service Layer for Business Logic
I chose to implement the affordability assessment logic in a dedicated `AffordabilityAssessor` service class rather than in the model or controller. This decision provides:

- **Separation of concerns:** Business logic is isolated from persistence and presentation layers
- **Testability:** The service can be unit tested independently of the Rails framework
- **Reusability:** The service can be used from controllers, background jobs, or other contexts
- **Maintainability:** Complex lending rules are centralized and easier to modify

#### 2. Structured Results with Value Objects
The `AffordabilityAssessor::Result` class uses a `Struct` with a custom `approved?` method to represent assessment outcomes. This provides:

- **Type safety:** Assessment results have a well-defined structure
- **Explicit interface:** The `approved?` predicate makes decisions clear
- **Immutable data:** Struct instances are immutable, preventing accidental modification
- **Better testing:** The structured result makes assertions cleaner in tests

#### 3. API-First Design with JSON Responses
The application is built as a pure JSON API with:

- **Consistent response format:** All endpoints return structured JSON with predictable keys
- **Proper HTTP status codes:** Using semantic status codes (201, 422, 404) for different outcomes
- **Input validation:** All required fields are validated with clear error messages
- **API versioning:** Endpoints are namespaced under `/api/v1/` for future evolution

### System Evolution

If this service needed to support a production mortgage platform, I would evolve the current implementation in several ways:

#### System Boundaries
- **Keep:** Core mortgage application model and assessment service as the central domain
- **Separate:** Authentication and authorization into a separate service (OAuth2 provider)
- **Separate:** Document management (proof of income, bank statements) into dedicated file service
- **Separate:** Credit scoring and third-party data checks into specialized services
- **Separate:** Reporting and analytics into a data warehouse pipeline

#### Handling Increased Load
- **Database:** Implement read replicas for reporting queries and connection pooling
- **Caching:** Add Redis caching for frequent affordability assessments and application lookups
- **Async Processing:** Move affordability assessments to background jobs for better throughput
- **Load Balancing:** Deploy multiple instances behind a load balancer
- **Database Sharding:** Consider sharding by customer region or application date for very large scale

#### Introducing Asynchronous Processing
- **Background Jobs:** Use Sidekiq or GoodJob for processing affordability assessments
- **Webhook Support:** Allow clients to receive notifications when assessments complete
- **Queuing System:** Implement priority queues for different assessment types
- **Batch Processing:** Support bulk assessments for pipeline applications
- **Status Tracking:** Add assessment status (pending, processing, completed, failed)

### Operational Considerations

#### Failure Handling
- **Circuit Breakers:** Implement circuit breakers for external service calls
- **Retry Logic:** Exponential backoff for transient failures
- **Graceful Degradation:** Serve cached results when services are unavailable
- **Dead Letter Queues:** Route failed assessments to review queues
- **Transaction Boundaries:** Use database transactions to ensure data consistency

#### Monitoring and Observability
- **Application Metrics:** Track request rates, response times, and error rates
- **Business Metrics:** Monitor approval rates, average LTV/DTI, and application volume
- **Error Tracking:** Integrate with error monitoring services (Sentry, Bugsnag)
- **Health Checks:** Implement health check endpoints for load balancers
- **Distributed Tracing:** Trace requests across service boundaries

#### Data Integrity and Auditability
- **Audit Logging:** Log all assessment decisions with reasoning and timestamps
- **Immutable Records:** Never delete assessments, only create new versions
- **Data Encryption:** Encrypt sensitive data at rest and in transit
- **Backup Strategy:** Regular database backups with point-in-time recovery
- **Compliance Logging:** Maintain logs for regulatory compliance requirements

### Change & Flexibility

Affordability rules change frequently and may be updated by non-engineering teams. To support this without constant redeployment:

#### Rule Configuration System
- **Database-Driven Rules:** Store lending criteria (LTV max, DTI max, deposit min) in database tables
- **Rule Versioning:** Maintain version history of all rule changes
- **A/B Testing:** Support testing new rules against current rules
- **Rule Evaluation Engine:** Build a flexible engine that can evaluate complex rule sets

#### Administrative Interface
- **Web Dashboard:** Provide non-technical users with UI to modify rules
- **Change Approval Workflow:** Implement approval processes for rule changes
- **Scheduled Changes:** Allow scheduling rule changes for future dates
- **Impact Analysis:** Show how many applications would be affected by proposed changes

#### Dynamic Rule Loading
- **Hot Reload:** Load new rules without application restart
- **Rule Caching:** Cache rules in memory with invalidation on changes
- **Rule Validation:** Validate new rules before activation
- **Fallback Rules:** Maintain safe defaults if rules become invalid

### Trade-offs & Prioritisation

Given limited time, I deliberately kept several aspects simple:

#### What I Kept Simple
1. **Authentication:** No authentication system was implemented. In production, this would be the first priority.
2. **Background Processing:** All assessments are synchronous. Async processing would be added for production.
3. **Database Schema:** Simple schema with minimal optimizations. Production would need indexing strategies.
4. **Error Handling:** Basic error handling. Production would need more sophisticated error scenarios.
5. **Documentation:** API documentation could be generated with OpenAPI/Swagger for production use.

#### What I Would Prioritise in 1-2 Weeks
1. **Authentication & Authorization:** Implement JWT-based auth with role-based access control
   - **Why:** Essential for production security and user management
   - **Impact:** Enables multi-tenant usage and audit trails

2. **Background Processing:** Move assessments to background jobs
   - **Why:** Improves user experience and system throughput
   - **Impact:** Allows handling of concurrent assessments without blocking

3. **Enhanced Error Handling & Monitoring**
   - **Why:** Critical for production reliability and debugging
   - **Impact:** Reduces Mean Time To Resolution (MTTR) for issues

4. **API Documentation:** Generate comprehensive API documentation
   - **Why:** Essential for developer experience and integration
   - **Impact:** Reduces integration time for API consumers

5. **Basic Caching:** Implement caching for application lookups and assessments
   - **Why:** Improves performance for repeated requests
   - **Impact:** Reduces database load and improves response times

These priorities address the most critical gaps while providing the foundation for a production-ready system.

## Technical Details

### Technologies Used
- **Ruby 3.4.4**
- **Rails 8.1.3**
- **PostgreSQL** (database)
- **RSpec** (testing framework)
- **FactoryBot** (test fixtures)
- **Shoulda Matchers** (model validation testing)

### Project Structure
```
mortgage_app/
├── app/
│   ├── controllers/api/v1/
│   │   └── mortgage_applications_controller.rb
│   ├── models/
│   │   ├── mortgage_application.rb
│   │   └── affordability_assessment.rb
│   └── services/
│       └── affordability_assessor.rb
├── spec/
│   ├── models/
│   ├── requests/api/v1/
│   └── services/
├── config/
│   └── routes.rb
├── db/
│   └── migrate/
├── Gemfile
└── README.md
```

### Development Notes

- The application uses Rails API mode for lightweight JSON responses
- All business logic is encapsulated in service objects
- Comprehensive test coverage for models, controllers, and services
- Database migrations include proper constraints and indexes
- Error handling follows Rails conventions with appropriate HTTP status codes